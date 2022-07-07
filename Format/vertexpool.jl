#Format Module - Main - Last Update: 06/07/2022

module Format

import ..CHUNK_SIZE,..RENDER_DISTANCE
export VertexPool

using ModernGL

const element_size = 7*sizeof(GLubyte)
const bucket_size = 6000
const max_bucket = RENDER_DISTANCE^3*6
const MAXSIZE = element_size*bucket_size*max_bucket

struct DrawCommand
    vertexCount::GLuint
    instanceCount::GLuint
    firstIndex::GLuint
    baseVertex::GLuint
    baseInstance::GLuint

    index::Int32
end

mutable struct VertexPool

    indirect_commands::Vector{DrawCommand}   #Array with all DAIC command

    ebo_buffer::GLuint      #Buffer with elements of instancing
    iao_buffer::GLuint     #Buffer with indirect array

    iao_pointers::Vector{Int32}       #iao: Pointers of all daic
    ebo_pointers::Vector{Ptr{Nothing}}      #Ebo: Pointers of all buckets
    free::Vector{Int32}       #Ebo: Free bucket's Pointers

    VertexPool() = new()

end

function vertexpool_init(vertexpool::VertexPool, ebo_buffer::GLuint, iao_buffer::GLuint)

    vertexpool.indirect_commands = DrawCommand[]
    vertexpool.ebo_buffer = ebo_buffer
    vertexpool.iao_buffer = iao_buffer
    vertexpool.iao_pointers = Int32[]
    vertexpool.ebo_pointers = GLuint[]
    vertexpool.free = Int32[]

    reserve(vertexpool)

end

function reserve(vertexpool::VertexPool)

    #Persistent Mapped Buffer Flags
    flags = GL_MAP_WRITE_BIT | GL_MAP_PERSISTENT_BIT | GL_MAP_COHERENT_BIT
    glNamedBufferStorage(vertexpool.ebo_buffer, MAXSIZE, C_NULL, flags)
    start_pointer = glMapNamedBufferRange(vertexpool.ebo_buffer, 0, MAXSIZE, flags)

    #Put bucket to free pointer
    local bucket_real_size = bucket_size*element_size
    for i in 0: max_bucket-1 

        push!(vertexpool.ebo_pointers,start_pointer+i*bucket_real_size)
        push!(vertexpool.iao_pointers,0)
        push!(vertexpool.free,i+1)

    end

end

#Create A new Bucket
function section!(vertexpool::VertexPool,data::Vector{GLubyte},instanceCount::Int,groupType::Int)
    
    #Remove the first free bucket
    bucket_indice = first(vertexpool.free)

    write!(vertexpool.ebo_pointers[bucket_indice],data)
    deleteat!(vertexpool.free,1) 

    #Create a DEIC with the bucket
    push!(vertexpool.indirect_commands,DrawCommand(6, instanceCount,0, groupType, bucket_size*(bucket_indice-1),bucket_indice))
    deic_indice = lastindex(vertexpool.indirect_commands)

    vertexpool.iao_pointers[bucket_indice] = deic_indice
    
    return bucket_indice

end

#Delete a Bucket with indice
function unsection!(vertexpool::VertexPool,bucket_indice::Int32)
    
    deic_indice = vertexpool.iao_pointers[bucket_indice]
    
    vertexpool.indirect_commands[deic_indice] = last(vertexpool.indirect_commands)
    vertexpool.iao_pointers[last(vertexpool.indirect).index] = deic_indice    #Copy Index
    deleteat!(vertexpool.indirect_commands,lastindex(vertexpool.indirect_commands))

    push!(vertexpool.free,bucket_indice)    #Bucket is now free

end

#Add new voxel in a bucket
function build!(vertexpool::VertexPool,bucket_indice::Int32,voxelData::Vector,instanceCount::Int)

    data_pointer = vertexpool.ebo_pointers[bucket_indice]
    deic_indice = vertexpool.iao_pointers[bucket_indice]
    deic = vertexpool.indirect_commands[deic_indice]

    write!(data_pointer+deic.instanceCount*element_size,voxelData)

    vertexpool.indirect_commands[deic.index] = DrawCommand(6,instanceCount+deic.instanceCount,0,deic.baseVertex,deic.baseInstance,deic.index)

end

#Delete a voxel with indice
function destroy!(vertexpool::VertexPool,bucket_indice::Int32,voxelPosition::Int)::Int

    data = vertexpool.ebo_pointers[bucket_indice]
    deic = vertexpool.indirect_commands[vertexpool.iao_pointers[bucket_indice]]

    bucket_length = deic.instanceCount*element_size

    mcopy!(data+voxelPosition*element_size,data+(bucket_length-element_size),element_size)
    vertexpool.indirect_commands[deic.index] = DrawCommand(6,deic.instanceCount-1,0,deic.baseVertex,deic.baseInstance,deic.index)

    return deic.instanceCount-1 #Last voxel changed

end

#Update Buckets
function update_vertexpool(pool::VertexPool)::Int
    #FACE CULLING
    #FRUSTRUM CULLING

    #if rot[2] < -5.3 || rot[2] > 5.3 || rot[2] > -0.9 && rot[2] < 0.9
    #    sort_list = [10,0,0,0,1,0,0,0,2,0,0,0,3,0,0,0,4,0,0,0,6]
    #    sort!(pool.indirect,by = v -> sort_list[v.baseVertex+1])
    #    number -=1
    #end  
    
    glNamedBufferData(pool.iao_buffer, sizeof(pool.indirect_commands),pool.indirect_commands, GL_DYNAMIC_DRAW)
    return length(pool.indirect_commands)
end


#TODO

#function gpu_synchronisation()
#    sync = glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE,0)
#    let waitReturn = GL_UNSIGNALED
#        while waitReturn != GL_ALREADY_SIGNALED && waitReturn != GL_CONDITION_SATISFIED
#            waitReturn = glClientWaitSync(sync, GL_SYNC_FLUSH_COMMANDS_BIT, 1)
#        end
#    end
#end




#C utils

mcopy!(dest::Ptr,src::Ptr,size::Int) = ccall(:memmove, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t),dest, src, size)
write!(pointer::Ptr,data::Vector{GLubyte}) = ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t),pointer, data, sizeof(data))


end
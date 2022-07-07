#Mesh Module - Main - Last Update: 07/07/2022

module Mesh

import ..RENDER_DISTANCE,..CHUNK_SIZE,..voxelColor
export MeshManager

mutable struct MeshManager

    pgame_map::Base.RefValue{Array{UInt8, 3}}
    pchunk_index::Base.RefValue{Dict{Tuple{Int32, Int32, Int32},Int32}}

    formated_mesh::Matrix{Vector{UInt8}}
    uniform_chunk::Dict{Tuple{Int64, Int64, Int64}, Int64}

    MeshManager() = new()

end

function meshmanager_init(meshmanager::MeshManager, generator::Main.Generation.Generator, vertexpool::Main.Format.VertexPool)

    meshmanager.pgame_map = Ref(generator.game_map)
    meshmanager.pchunk_index = Ref(generator.chunk_index)

    meshmanager.formated_mesh = Array{Vector{UInt8},2}(undef,RENDER_DISTANCE^3,6)
    meshmanager.uniform_chunk = Dict{Tuple{Int64, Int64, Int64}, Int64}()

    @fastmath @inbounds create_map_mesh(meshmanager)

    reserve_bucket(meshmanager,vertexpool)

end

function reserve_bucket(meshmanager::MeshManager, vertexpool::Main.Format.VertexPool)

    #Reserve bucket in vertexpool (6 times for each faces)

    for mesh in 1:RENDER_DISTANCE^3
        for type in 0:5

            bucket_data = meshmanager.formated_mesh[mesh,type+1]
            Main.Format.section!(vertexpool,bucket_data, Int(length(bucket_data)/7) ,type*4)
        
        end
    end
end

function update_chunk_uniform(meshmanager::MeshManager, renderer::Main.Graphics.Renderer)

    for (chunk,value) in meshmanager.uniform_chunk
        Main.Graphics.glUniform3f(Main.Graphics.glGetUniformLocation(renderer.shader_prog, "chunk_pos[$value]"),chunk[1],chunk[2],chunk[3])
    end

end

@polly function create_map_mesh(meshmanager::MeshManager)

    #Uniform chunk creation
    for chunkX in 0:RENDER_DISTANCE-1
        for chunkY in 0:RENDER_DISTANCE-1
            for chunkZ in 0:RENDER_DISTANCE-1

                local offsetChunkX = div(chunkX, 8)
                local offsetChunkY = div(chunkY, 8)
                local offsetChunkZ = div(chunkZ, 8)

                local uniform_chunk_position = (offsetChunkX*256,offsetChunkY*256,offsetChunkZ*256)
                
                if !haskey(meshmanager.uniform_chunk,uniform_chunk_position)
                    meshmanager.uniform_chunk[uniform_chunk_position] = length(meshmanager.uniform_chunk)

                end
            end
        end
    end

    Threads.@threads for chunkX in 0:RENDER_DISTANCE-1
        for chunkY in 0:RENDER_DISTANCE-1
            for chunkZ in 0:RENDER_DISTANCE-1

                local offsetChunkX = div(chunkX, 8)
                local offsetChunkY = div(chunkY, 8)
                local offsetChunkZ = div(chunkZ, 8)

                local uniform_chunk_position = (offsetChunkX*256,offsetChunkY*256,offsetChunkZ*256)

                uniform_index = meshmanager.uniform_chunk[uniform_chunk_position]

                @fastmath @inbounds update_chunk_mesh(meshmanager,chunkX,chunkY,chunkZ, uniform_index)

            end
        end
    end

end

@polly function update_chunk_mesh(meshmanager::MeshManager,chunkX::Int,chunkY::Int,chunkZ::Int,uniform_index::Int64)

    chunk_index = meshmanager.pchunk_index[][chunkX,chunkY,chunkZ]
    chunk = meshmanager.pgame_map[][chunk_index,:,:]

    meshmanager.formated_mesh[chunk_index,:] = [[],[],[],[],[],[]]

    local realChunkX = chunkX*CHUNK_SIZE    #CHUNK_SIZE value
    local realChunkY = chunkY*CHUNK_SIZE
    local realChunkZ = chunkZ*CHUNK_SIZE

    local voxel_index = 0

    for voxelX in 1:CHUNK_SIZE
        for voxelY in 1:CHUNK_SIZE
            for voxelZ in 1:CHUNK_SIZE
                
                voxel_index += 1
                voxel = chunk[voxel_index,1]

                #ETAPE SUPPLEMENTAIRE A FAIRE

                if voxel != 0
                    
                    posX = (voxelX -1 + realChunkX) % 256
                    posY = (voxelY -1 + realChunkY) % 256
                    posZ = (voxelZ -1 + realChunkZ) % 256

                    color = (voxelColor[voxel][1]+rand(-3:3),voxelColor[voxel][2]+rand(-3:3),voxelColor[voxel][3]+rand(-3:3))
 
                    if get_blockInfo(meshmanager,chunkX,chunkY,chunkZ,voxelX-1,voxelY,voxelZ) == 0
                        
                        push!(meshmanager.formated_mesh[chunk_index,4], posX,posY,posZ,color[1],color[2],color[3],uniform_index)
                    end
                    if get_blockInfo(meshmanager,chunkX,chunkY,chunkZ,voxelX+1,voxelY,voxelZ) == 0
                        
                        push!(meshmanager.formated_mesh[chunk_index,2], posX,posY,posZ,color[1],color[2],color[3],uniform_index)
                    end
                    if get_blockInfo(meshmanager,chunkX,chunkY,chunkZ,voxelX,voxelY-1,voxelZ) == 0
                        
                        push!(meshmanager.formated_mesh[chunk_index,3], posX,posY,posZ,color[1],color[2],color[3],uniform_index)
                    end
                    if get_blockInfo(meshmanager,chunkX,chunkY,chunkZ,voxelX,voxelY+1,voxelZ) == 0
                        
                        push!(meshmanager.formated_mesh[chunk_index,6], posX,posY,posZ,color[1],color[2],color[3],uniform_index)
                    end
                    if get_blockInfo(meshmanager,chunkX,chunkY,chunkZ,voxelX,voxelY,voxelZ-1) == 0
                        
                        push!(meshmanager.formated_mesh[chunk_index,1], posX,posY,posZ,color[1],color[2],color[3],uniform_index)
                    end
                    if get_blockInfo(meshmanager,chunkX,chunkY,chunkZ,voxelX,voxelY,voxelZ+1) == 0
                        
                        push!(meshmanager.formated_mesh[chunk_index,5], posX,posY,posZ,color[1],color[2],color[3],uniform_index)

                    end
                end
            end
        end
    end
end


@polly function get_blockInfo(meshmanager::MeshManager,chunkX::Int,chunkY::Int,chunkZ::Int,x::Int,y::Int,z::Int)::Int8

    if x == 0 
        chunkX-=1
        x = CHUNK_SIZE
    elseif x == CHUNK_SIZE+1 
        chunkX+=1
        x = 1
    end

    if y == 0
        chunkY-=1
        y = CHUNK_SIZE
    elseif y == CHUNK_SIZE+1
        chunkY+=1
        y = 1
    end

    if z == 0
        chunkZ-=1
        z = CHUNK_SIZE
    elseif z == CHUNK_SIZE+1
        chunkZ+=1
        z = 1
    end

    chunk_index = get(meshmanager.pchunk_index[],(chunkX,chunkY,chunkZ),-1)
    if chunk_index != -1
        return @inbounds meshmanager.pgame_map[][chunk_index,(x-1)*CHUNK_SIZE^2+(y-1)*CHUNK_SIZE+z,1]
    else return 1 end

end
        
end
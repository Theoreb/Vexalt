#Generation Module - Main - Last Update: 07/07/2022

module Generation

import ..CHUNK_SIZE,..RENDER_DISTANCE
export Generator

include(joinpath(@__DIR__,"voxelgen.jl"))

mutable struct Generator

    game_map::Array{UInt8, 3}

    chunk_index::Dict{Tuple{Int32, Int32, Int32},Int32}

    Generator() = new()

end

function generator_init(generator::Generator)

    generator.game_map = Array{UInt8}(undef,RENDER_DISTANCE^3,CHUNK_SIZE^3,2)
    generator.chunk_index = Dict{Tuple{Int32, Int32, Int32},Int32}()

    create_game_map(generator)

end

@polly function create_game_map(generator::Generator)

    chunk_index = 0

    #Chunk Index Creation
    for chunkX in 0:RENDER_DISTANCE-1
        for chunkY in 0:RENDER_DISTANCE-1
            for chunkZ in 0:RENDER_DISTANCE-1
                chunk_index += 1
                generator.chunk_index[chunkX,chunkY,chunkZ] = chunk_index
            end
        end
    end

    #Multi Threading Power
    Threads.@threads for (chunk,index) in collect(generator.chunk_index)

        @inbounds generator.game_map[index,:,:] = generate_chunk(chunk[1],chunk[2],chunk[3])

    end

end

@polly function generate_chunk(chunkX::Int32,chunkY::Int32,chunkZ::Int32)::Array{UInt8, 2}
    chunkData = Array{UInt8, 2}(undef, CHUNK_SIZE^3,2)

    local offsetX = chunkX*CHUNK_SIZE
    local offsetY = chunkY*CHUNK_SIZE
    local offsetZ = chunkZ*CHUNK_SIZE

    voxel_index = 0 

    for voxelX in 1:CHUNK_SIZE
        for voxelY in 1:CHUNK_SIZE
            for voxelZ in 1:CHUNK_SIZE

                voxel_index += 1

                voxel_type = generate_voxel(offsetX + voxelX, offsetY + voxelY, offsetZ + voxelZ)
                chunkData[voxel_index,1] = voxel_type

            end
        end
    end

    return chunkData

end


end
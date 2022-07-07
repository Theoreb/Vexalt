#Generation Module - voxelgen.jl - Last Update: 07/07/2022

include(joinpath(@__DIR__,"perlin","OpenSimplex.jl"))

import ..SEED

function generate_voxel(posX::Int,posY::Int,posZ::Int)::UInt8
    voxelData = 0x00

    @fastmath density = round(OpenSimplex.noise(SEED,posX*0.01,posZ*0.01)*130)
    @fastmath plains = round(OpenSimplex.noise(SEED,posX*0.05,posZ*0.05)*20)
    @fastmath beach = round(OpenSimplex.noise(SEED,posX*0.02,posZ*0.02)*20)

    @fastmath snow = OpenSimplex.noise(SEED,posX*0.05,posY*0.05,posZ*0.05)

    @fastmath hardrock = OpenSimplex.noise(SEED,posX*0.1,posY*0.1,posZ*0.1)
    @fastmath rock = OpenSimplex.noise(SEED,posX*0.08,posY*0.08,posZ*0.08)

    @fastmath big_moutain = round(OpenSimplex.noise(SEED,posX*0.01,posZ*0.01)*170)

    @fastmath wood = round(OpenSimplex.noise(SEED,posX*0.1,posZ*0.1)*200)


    if posY <= density || posY <= big_moutain
        voxelData = 2 end

    if density < posY && posY < 40
        voxelData = 4
    end

    if posY <47 && posY <= 40+beach
        voxelData = 5
    end

    if posY <= 45+plains
        voxelData = 2
    end

    if rock+(posY-40)*0.01 > 0.6 && voxelData == 2
        voxelData = 1

        if hardrock > 0.5
            voxelData = 3 end

        if snow+(posY-60)*0.01 > 0.8
            voxelData = 6 end
    end



    return voxelData

end
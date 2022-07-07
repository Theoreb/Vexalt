#Main File - Last Update: 07/07/2022

include(joinpath(@__DIR__,"Engine.jl"))

function main()

    engine = Engine() 

    init!(engine)

    engine.renderer.camera.movingSpeed = 50.0
    Graphics.setposition!(engine.renderer.camera,[100,300,100])


    while is_running(engine)

        update!(engine)

    end
    terminate!(engine)

end

main()
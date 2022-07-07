#Engine version 0.0.0 - Last Update: 07/07/2022

const DEBUG_MODE = true

const SEED = rand(-9999999:9999999)

const RENDER_DISTANCE = 17
const CHUNK_SIZE = 32

include(joinpath(@__DIR__,"Data","blocktype.jl"))
include(joinpath(@__DIR__,"Graphics","renderer.jl"))
include(joinpath(@__DIR__,"Format","vertexpool.jl"))
include(joinpath(@__DIR__,"Generation","generator.jl"))
include(joinpath(@__DIR__,"Mesh","meshmanager.jl"))

mutable struct Engine
    
    renderer::Graphics.Renderer
    vertexpool::Format.VertexPool
    meshmanager::Mesh.MeshManager
    generator::Generation.Generator

end
Engine() = Engine( Graphics.Renderer() , Format.VertexPool() , Mesh.MeshManager() , Generation.Generator() )

function init!(engine::Engine)

    Graphics.renderer_init(engine.renderer)
    Format.vertexpool_init(engine.vertexpool, engine.renderer.ebo, engine.renderer.iao)
    Generation.generator_init(engine.generator)
    Mesh.meshmanager_init(engine.meshmanager, engine.generator,engine.vertexpool)

    Format.update_vertexpool(engine.vertexpool)  #One time on start

    Mesh.update_chunk_uniform(engine.meshmanager, engine.renderer)

end

function update!(engine::Engine)
    
    Graphics.update_renderer(engine.renderer,length(engine.vertexpool.indirect_commands),sizeof(Format.DrawCommand))

end

is_running(engine::Engine) = !Graphics.GLFW.WindowShouldClose(engine.renderer.window)
terminate!(engine::Engine) = Graphics.GLFW.DestroyWindow(engine.renderer.window)

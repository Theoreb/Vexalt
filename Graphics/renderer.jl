#Renderer Module - Main - Last Update: 06/07/2022

module Graphics

export Renderer

using Quaternions
using LinearAlgebra
using StaticArrays
using ModernGL
using CSyntax
using GLFW


include(joinpath(@__DIR__,"camera.jl"))
include(joinpath(@__DIR__,"constances.jl"))
include(joinpath(@__DIR__,"glfwutils.jl"))
include(joinpath(@__DIR__,"openglutils.jl"))


mutable struct Renderer
    
    window::GLFW.Window

    camera::PerspectiveCamera

    vao::GLuint     #Vertex Array Object
    vbo::GLuint     #Vertex Buffer Object
    ibo::GLuint     #Indice Buffer Object
    ebo::GLuint     #Element Buffer Object
    iao::GLuint     #Indirect Array Object

    vert_shader::GLuint     #Shader
    frag_shader::GLuint
    shader_prog::GLuint
    
    model_loc::GLuint       #Matrices
    view_loc::GLuint
    proj_loc::GLuint
    model_mat::Matrix{Float32}

    Renderer() = new()

end



function renderer_init(renderer::Renderer)

    create_window(renderer)
    create_context()
    create_camera(renderer)
    create_buffers(renderer)
    create_shaders(renderer)
    init_opengl(renderer)

end





create_window(renderer::Renderer) = renderer.window = new_window("Engine - Version 0.0.1", 1000 , 1000)

create_context() = start_glcontext()

create_camera(renderer::Renderer) = renderer.camera = PerspectiveCamera()

function create_buffers(renderer::Renderer)

    renderer.vao = VertexArray()
    renderer.vbo = Buffer()
    renderer.ibo = Buffer()
    renderer.ebo = Buffer()
    renderer.iao = Buffer()

    #VBO
    set_buffer_data(renderer.vbo,vertices,GL_STATIC_DRAW)
    set_buffer_attribute(renderer.vao,0,3,0,0,0, GL_BYTE, GL_FALSE)
    link_vertice_buffer(renderer.vao,renderer.vbo,3*sizeof(GLbyte),0,0)

    #IBO
    set_buffer_data(renderer.ibo,indices,GL_STATIC_DRAW)
    link_indice_buffer(renderer.vao,renderer.ibo)

    #EBO
    set_buffer_attribute(renderer.vao,1,3,1,0,1, GL_UNSIGNED_BYTE, GL_FALSE)               #Position (3 UInt8)
    link_vertice_buffer(renderer.vao,renderer.ebo,7*sizeof(GLubyte),0,1)

    set_buffer_attribute(renderer.vao,2,3,1,0,2, GL_UNSIGNED_BYTE, GL_TRUE)                #Color  (3 UInt8)
    link_vertice_buffer(renderer.vao,renderer.ebo,7*sizeof(GLubyte),3*sizeof(GLubyte),2)

    set_Ibuffer_attribute(renderer.vao,3,1,1,0,3, GL_UNSIGNED_BYTE)                        #Chunk Index (1 UInt8)
    link_vertice_buffer(renderer.vao,renderer.ebo,7*sizeof(GLubyte),6*sizeof(GLubyte),3)

end

function create_shaders(renderer::Renderer)

    renderer.vert_shader = createshader(joinpath(@__DIR__, "shaders","voxel.vert"), GL_VERTEX_SHADER)
    renderer.frag_shader = createshader(joinpath(@__DIR__, "shaders","voxel.frag"), GL_FRAGMENT_SHADER)

    renderer.shader_prog = createprogram(renderer.vert_shader, renderer.frag_shader)

    renderer.model_loc = glGetUniformLocation(renderer.shader_prog, "model_mat")
    renderer.view_loc = glGetUniformLocation(renderer.shader_prog, "view_mat")
    renderer.proj_loc = glGetUniformLocation(renderer.shader_prog, "projection_mat")

    glUseProgram(renderer.shader_prog)

    renderer.model_mat = Matrix{GLfloat}(I, 4, 4)
    glUniformMatrix4fv(renderer.model_loc, 1, GL_FALSE, renderer.model_mat)
    glUniformMatrix4fv(renderer.view_loc, 1, GL_FALSE, get_view_matrix(renderer.camera))
    glUniformMatrix4fv(renderer.proj_loc, 1, GL_FALSE, get_projective_matrix(renderer.window, renderer.camera))

end

function init_opengl(renderer::Renderer)

    glBindVertexArray(renderer.vao)
    glBindBuffer(GL_DRAW_INDIRECT_BUFFER,renderer.iao)
    glUseProgram(renderer.shader_prog)

end

function update_renderer(renderer::Renderer,length::Int64,daic_size::Int)

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, GLFW.GetFramebufferSize(renderer.window)...)     #PERFORMANCE ISSUE

    glUniformMatrix4fv(renderer.model_loc, 1, GL_FALSE, renderer.model_mat)          #PERFORMANCE ISSUE

    #glMultiDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_BYTE,render.vertex_pool.indirect,1,sizeof(DrawCommand))
    glMultiDrawElementsIndirect(GL_TRIANGLES,GL_UNSIGNED_BYTE,C_NULL,length,daic_size)
    GLFW.PollEvents()

    updatekey!(renderer.window)
    updatecamera!(renderer.window, renderer.camera) 
    updatemouse!(renderer.window, renderer.camera)

    glUniformMatrix4fv(renderer.view_loc, 1, GL_FALSE, get_view_matrix(renderer.camera))
    GLFW.SwapBuffers(renderer.window)

end



end
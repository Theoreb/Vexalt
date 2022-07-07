#Renderer Module - openglutils.jl - Last Update: 06/07/2022

function VertexArray()::GLuint
    VAO = GLuint(0)
    @c glCreateVertexArrays(1, &VAO)

    return VAO
end

function Buffer()::GLuint
    buffer = GLuint(0)
    @c glCreateBuffers(1, &buffer)

    return buffer
end



function set_buffer_data(buffer::ModernGL.GLuint,data::Vector, parameters::UInt32)
    glNamedBufferData(buffer, sizeof(data), data, parameters)
end

function set_buffer_attribute(VAO::ModernGL.GLuint, vertex_layout::Int, vertex_length::Int, update_frequency::Int, vertex_first_offset::Int,bindingindex::Int, vertex_type::UInt32, normalised::UInt32=GL_FALSE)
    glEnableVertexArrayAttrib(VAO , vertex_layout)
    glVertexArrayAttribBinding(VAO,vertex_layout,bindingindex)
    glVertexArrayAttribFormat(VAO, vertex_layout, vertex_length, vertex_type, normalised,vertex_first_offset)
    glVertexArrayBindingDivisor(VAO, vertex_layout, update_frequency)
end

function set_Ibuffer_attribute(VAO::ModernGL.GLuint, vertex_layout::Int, vertex_length::Int, update_frequency::Int, vertex_first_offset::Int,bindingindex::Int, vertex_type::UInt32)
    glEnableVertexArrayAttrib(VAO , vertex_layout)
    glVertexArrayAttribBinding(VAO,vertex_layout,bindingindex)
    glVertexArrayAttribIFormat(VAO, vertex_layout, vertex_length, vertex_type,vertex_first_offset)
    glVertexArrayBindingDivisor(VAO, vertex_layout, update_frequency)
end

function link_vertice_buffer(VAO::ModernGL.GLuint,VBO::ModernGL.GLuint,bytedistance_between_vertex::Int, vertex_first_offset::Int = 0, bindingindex::Int=0)
    glVertexArrayVertexBuffer(VAO, bindingindex, VBO, vertex_first_offset, bytedistance_between_vertex)
end

function link_indice_buffer(VAO::ModernGL.GLuint,IBO::ModernGL.GLuint)
    glVertexArrayElementBuffer(VAO, IBO)
end




function createshader(path::AbstractString, type::GLenum)
    source = read(path, String)
    id = glCreateShader(type)
    glShaderSource(id, 1, Ptr{GLchar}[pointer(source)], C_NULL)
    glCompileShader(id)
    # get shader compile status and print logs
    result = GLint(-1)
    @c glGetShaderiv(id, GL_COMPILE_STATUS, &result)
    if result != GL_TRUE
        @error "$(GLENUM(type).name)(id:$id) failed to compile!"
        max_length = GLint(0)
        @c glGetShaderiv(id, GL_INFO_LOG_LENGTH, &max_length)
        actual_length = GLsizei(0)
        log = Vector{GLchar}(undef, max_length)
        @c glGetShaderInfoLog(id, max_length, &actual_length, log)
        @error String(log)
    end
    @info "$(GLENUM(type).name)(id:$id) successfully compiled!"
    return id
end

# create program
function createprogram(shaders::GLuint...)
    id = glCreateProgram()
    @info "Creating program(id:$id) ..."
    for shader in shaders
        @info "  attempting to attach shader(id:$shader) ..."
        glAttachShader(id, shader)
    end
    glLinkProgram(id)
    # checkout linking status
    result = GLint(-1)
    @c glGetProgramiv(id, GL_LINK_STATUS, &result)
    if result != GL_TRUE
        @error "Could not link shader program(id:$id)!"
		max_length = GLint(0)
        @c glGetProgramiv(id, GL_INFO_LOG_LENGTH, &max_length)
        actual_length = GLsizei(0)
        log = Vector{GLchar}(undef, max_length)
        @c glGetProgramInfoLog(id, max_length, &actual_length, log)
        @error String(log)
        error("Could not link shader program(id:$id)!")
    end
    @assert is_valid(id)
	foreach(id->glDeleteShader(id), shaders)
    return id
end

# print errors in shader compilation
function shader_info_log(shader::GLuint)
    max_length = GLint(0)
    @c glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &max_length)
    actual_length = GLsizei(0)
    log = Vector{GLchar}(undef, max_length)
    @c glGetShaderInfoLog(shader, max_length, &actual_length, log)
    @info "shader info log for GL index $shader: $(String(log))"
end

# print errors in shader linking
function programme_info_log(program::GLuint)
    max_length = GLint(0)
    @c glGetShaderiv(program, GL_INFO_LOG_LENGTH, &max_length)
    actual_length = GLsizei(0)
    log = Vector{GLchar}(undef, max_length)
    @c glGetShaderInfoLog(program, max_length, &actual_length, log)
    @info "program info log for GL index $program: $(String(log))"
end

# validate shader program
function is_valid(program::GLuint)
    params = GLint(-1)
    glValidateProgram(program)
    @c glGetProgramiv(program, GL_VALIDATE_STATUS, &params)
    @info "program $program GL_VALIDATE_STATUS = $params"
    params == GL_TRUE && return true
    programme_info_log(program)
    return false
end



function glDebugOutput(source::GLenum, type::GLenum , id::GLuint, severity::GLenum,length::GLsizei, message, userParam)

    if source == GL_DEBUG_SOURCE_API source_string = "OpengGL API" elseif source == GL_DEBUG_SOURCE_WINDOW_SYSTEM source_string = "Window-System API"
    elseif source == GL_DEBUG_SOURCE_SHADER_COMPILER source_string = "Shader Compiler" elseif source == GL_DEBUG_SOURCE_THIRD_PARTY source_string = "External Application"
    elseif source == GL_DEBUG_SOURCE_APPLICATION source_string = "Current Application" elseif source == GL_DEBUG_SOURCE_OTHER source_string = "Unknown Source" end

    if type == GL_DEBUG_TYPE_ERROR type_string = "API Error" elseif type == GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR type_string = "Deprecated Behavior"
    elseif type == GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR type_string = "Undefined Behavior" elseif type == GL_DEBUG_TYPE_PORTABILITY type_string = "Portability Error"
    elseif type == GL_DEBUG_TYPE_PERFORMANCE type_string = "Performance Warning" elseif type == GL_DEBUG_TYPE_MARKER type_string = "Marker Error"
    elseif type == GL_DEBUG_TYPE_PUSH_GROUP type_string = "	Group pushing" elseif type == GL_DEBUG_TYPE_POP_GROUP type_string = "	Group popping"
    elseif type == GL_DEBUG_TYPE_OTHER type_string = "Unknown Source" end

    if severity == GL_DEBUG_SEVERITY_HIGH severity_string = "HIGHT" elseif severity == GL_DEBUG_SEVERITY_MEDIUM severity_string = "MEDIUM"
    elseif severity == GL_DEBUG_SEVERITY_LOW severity_string = "LOW" elseif severity == GL_DEBUG_SEVERITY_NOTIFICATION severity_string = "!" end

    message_string = unsafe_string(message,length)
    io = IOBuffer()
    Base.show_backtrace(io, backtrace()[1:10] )
    value = String(take!(io))

    result = "\e[31m\e[1m[$severity_string]\e[22m\e[39m [$source_string]: \e[32m\e[1m$type_string\e[39m :\e[22m $message_string $value"
    
    if severity == GL_DEBUG_SEVERITY_HIGH @error result
    elseif severity == GL_DEBUG_SEVERITY_MEDIUM @warn result end

    return 0

end



function start_glcontext()

    glEnable(GL_DEPTH_TEST)
    glDepthFunc(GL_LESS)
    glClearColor(0.2, 0.5, 1.0, 1.0)

    if DEBUG_MODE

        GLFW.WindowHint(GLFW.OPENGL_DEBUG_CONTEXT,true)

        renderer = unsafe_string(glGetString(GL_RENDERER))
        version = unsafe_string(glGetString(GL_VERSION))

        threads_number = Threads.nthreads()

        @info GLFW.GetVersionString()
        @info "Renderer: $renderer"
        @info "OpenGL version supported: $version"
        @info "Threads Used: $threads_number"

        debugFunction = @cfunction(glDebugOutput,Int,(GLenum,GLenum,GLuint,GLenum,GLsizei,Ptr{GLchar},Ptr{Cvoid}))
        
        glEnable(GL_DEBUG_OUTPUT)
        glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS)
        glDebugMessageCallback(debugFunction, C_NULL)
        glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, C_NULL, GL_TRUE)

    end

end
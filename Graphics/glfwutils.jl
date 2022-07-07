#Renderer Module - glfwutils.jl - Last Update: 06/07/2022

import ..DEBUG_MODE

function new_window(windowName::String,windowWidth::Int,windowHeight::Int)

    @static if Sys.isapple()
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, VERSION_MAJOR)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, VERSION_MINOR)
        GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
        GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
    else
        GLFW.DefaultWindowHints()
    end

	window = GLFW.CreateWindow(windowWidth, windowHeight, windowName)
	@assert window != C_NULL "Could not open window with GLFW3"

    GLFW.SetErrorCallback(glfw_error_callback)
	GLFW.SetKeyCallback(window, glfw_key_callback)
    GLFW.SetInputMode(window,GLFW.STICKY_KEYS,true)

	GLFW.MakeContextCurrent(window)
	GLFW.WindowHint(GLFW.SAMPLES, 4)

    GLFW.WindowHint(GLFW.RESIZABLE, 1)
    GLFW.WindowHint(GLFW.VISIBLE, 1)
    GLFW.WindowHint(GLFW.FOCUSED, 1)

    GLFW.SetInputMode(window,GLFW.CURSOR,GLFW.CURSOR_HIDDEN)


    if DEBUG_MODE GLFW.WindowHint(GLFW.OPENGL_DEBUG_CONTEXT,true) end

    return window

end

glfw_error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"

function glfw_key_callback(window::GLFW.Window, key::GLFW.Key, scancode::Cint, action::GLFW.Action, mods::Cint)

    if key == GLFW.KEY_ESCAPE && action == GLFW.PRESS
        GLFW.SetInputMode(window,GLFW.CURSOR, GLFW.CURSOR_NORMAL) end

end

function updatemouse!(window::GLFW.Window,camera::PerspectiveCamera)
        xpos,ypos = GLFW.GetCursorPos(window)

        windowSize = GLFW.GetWindowSize(window)
        GLFW.SetCursorPos(window,windowSize[1]/2,windowSize[2]/2)
        x = (windowSize[1]/2 - xpos)
        y = (windowSize[2]/2 - ypos)
        rotate!(camera, camera.right, y )
        rotate!(camera, camera.up, x )
        update_view_matrix!(camera, zeros(GLfloat, 3))
        get_view_matrix(camera)

end

function updatekey!(window::GLFW.Window)
    state = GLFW.GetKey(window, GLFW.KEY_ESCAPE)
    if state == true
        GLFW.SetWindowShouldClose(window, true)
    end

end
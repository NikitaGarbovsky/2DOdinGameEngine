package input

import sdl "vendor:sdl3"

///
/// Manages the input of the application, through sdl3 input.
///

// Helper to reset input state before reading input per frame.
ResetInputState :: proc(_inputS: ^InputState) {
    _inputS.left_pressed = false
    _inputS.delete_pressed = false
}

// Defines sdl input definitions, processes any input per frame.
ProcessSDLEvents :: proc(
    _input: ^InputState,
    _running: ^bool,
    _width: ^i32,
    _height: ^i32,
    _event_callback: Event_Callback,
) {
    ResetInputState(_input)

    ev: sdl.Event
    for sdl.PollEvent(&ev) {
        if _event_callback != nil {
            _event_callback(&ev)
        }

        #partial switch ev.type {
        case .QUIT:
            _running^ = false

        case .MOUSE_MOTION:
            _input.mouse_x = f32(ev.motion.x)
            _input.mouse_y = f32(ev.motion.y)

        case .MOUSE_BUTTON_DOWN:
            if ev.button.button == sdl.BUTTON_LEFT {
                if !_input.left_down {
                    _input.left_pressed = true
                }
                _input.left_down = true
            }

        case .MOUSE_BUTTON_UP:
            if ev.button.button == sdl.BUTTON_LEFT {
                _input.left_down = false
            }

        case .KEY_DOWN:
            if !ev.key.repeat {
                if ev.key.scancode == sdl.GetScancodeFromName("Delete") {
                    _input.delete_pressed = true
                    _input.delete_down = true
                }
            }

        case .KEY_UP:
            if ev.key.scancode == sdl.GetScancodeFromName("Delete") {
                _input.delete_down = false
            }

        case .WINDOW_RESIZED:
            _width^ = ev.window.data1
            _height^ = ev.window.data2
        }
    }
}
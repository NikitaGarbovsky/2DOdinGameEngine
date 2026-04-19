#+vet explicit-allocators
package input

import sdl "vendor:sdl3"

///
/// Manages the input of the application, through sdl3 input.
///

// Helper to reset input state before reading input per frame.
ResetInputState :: proc(_inputS: ^InputState) {
    _inputS.left_pressed = false
    _inputS.delete_pressed = false
    _inputS.mouse_scroll_down = 0
    _inputS.mouse_scroll_up = 0

    _inputS.mouse_dx = 0
    _inputS.mouse_dy = 0

    _inputS.toggle_appmode_pressed = false
}

// Defines sdl input definitions, processes any input per update loop.
ProcessSDLEvents :: proc(
    _input: ^InputState,
    _running: ^bool,
    _width: ^i32,
    _height: ^i32,
    _editorInputEventCallback: Event_Callback,
) {
    ResetInputState(_input)

    ev: sdl.Event
    for sdl.PollEvent(&ev) {
        if _editorInputEventCallback != nil {
            _editorInputEventCallback(&ev)
        }

        #partial switch ev.type {
        case .QUIT:
            _running^ = false

        case .MOUSE_MOTION:
            _input.mouse_x = f32(ev.motion.x)
            _input.mouse_y = f32(ev.motion.y)
            _input.mouse_dx += f32(ev.motion.xrel)
            _input.mouse_dy += f32(ev.motion.yrel)

        case .MOUSE_BUTTON_DOWN:
            if ev.button.button == sdl.BUTTON_LEFT {
                if !_input.left_down {
                    _input.left_pressed = true
                }
                _input.left_down = true
            }

            if ev.button.button == sdl.BUTTON_RIGHT {
                _input.right_down = true
            }

        case .MOUSE_BUTTON_UP:
            if ev.button.button == sdl.BUTTON_LEFT {
                _input.left_down = false
            }
            if ev.button.button == sdl.BUTTON_RIGHT {
                _input.right_down = false
            }

        case .KEY_DOWN:
            if !ev.key.repeat {
                if ev.key.scancode == sdl.GetScancodeFromName("Delete") {
                    _input.delete_pressed = true
                    _input.delete_down = true
                }

                if ev.key.scancode == sdl.GetScancodeFromName("Space") {
                    _input.space_down = true
                }

                if ev.key.scancode == sdl.GetScancodeFromName("F5") {
                    _input.toggle_appmode_pressed = true
                }

                if ev.key.scancode == sdl.GetScancodeFromName("W") {
                    _input.move_up = true
                }

                if ev.key.scancode == sdl.GetScancodeFromName("A") {
                    _input.move_left = true
                }
                
                if ev.key.scancode == sdl.GetScancodeFromName("S") {
                    _input.move_down = true
                }
                
                if ev.key.scancode == sdl.GetScancodeFromName("D") {
                    _input.move_right = true
                }
            }

        case .KEY_UP:
            if ev.key.scancode == sdl.GetScancodeFromName("Delete") {
                _input.delete_down = false
            }

            if ev.key.scancode == sdl.GetScancodeFromName("Space") {
                _input.space_down = false
            }

            if ev.key.scancode == sdl.GetScancodeFromName("F5") {
                _input.toggle_appmode_pressed = false
            }
            if ev.key.scancode == sdl.GetScancodeFromName("W") {
                    _input.move_up = false
            }

            if ev.key.scancode == sdl.GetScancodeFromName("A") {
                _input.move_left = false
            }
            
            if ev.key.scancode == sdl.GetScancodeFromName("S") {
                _input.move_down = false
            }
            
            if ev.key.scancode == sdl.GetScancodeFromName("D") {
                _input.move_right = false
            }

        case .WINDOW_RESIZED:
            _width^ = ev.window.data1
            _height^ = ev.window.data2

        case .MOUSE_WHEEL: 
            if ev.wheel.y > 0 {
                _input.mouse_scroll_up = ev.wheel.y
            }
            if ev.wheel.y < 0 {
                _input.mouse_scroll_down = ev.wheel.y
            }
        }
    }
}
package input

import sdl "vendor:sdl3"

///
/// Defines input types used by input
/// 


// Object managing the state of input, position, mouse click, button press.
InputState :: struct {
    mouse_x : f32,
    mouse_y : f32,
    mouse_dx : f32,
    mouse_dy : f32,

    left_down    : bool,
    left_pressed : bool,

    right_down : bool,
    
    delete_down    : bool,
    delete_pressed : bool,

    space_down : bool,
}

// Used by editor imgui to process sdl events (input, editorimgui has priority)
Event_Callback :: proc(ev: ^sdl.Event)
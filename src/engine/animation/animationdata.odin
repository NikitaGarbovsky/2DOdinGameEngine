package animation 

import glm "core:math/linalg"

Animation_Frame :: struct {
    uv_min : glm.Vector2f32,
    uv_max : glm.Vector2f32,
    duration : f32,
    origin : glm.Vector2f32,
    size : glm.Vector2f32,
}

Animation_Clip :: struct {
    name : string, 
    frames : []Animation_Frame,
    looping : bool,
}

Animation_Player :: struct {
    current_clip : Animation_Clip,
    current_frame : int,
    frame_time : f32,
    playing : bool,
    speed : f32,
    just_finished : bool,
    flip_x : bool,
}


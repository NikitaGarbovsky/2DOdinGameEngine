package animation 

import "../renderdata"
import glm "core:math/linalg"

Animation_Bank :: struct {
    animation_clips : [dynamic]Animation_Clip,
}

player_anim_bank : Animation_Bank

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
    source_path : string,
    texture : renderdata.Texture_Handle,
}

Animation_Player :: struct {
    current_clip : Animation_Clip,
    current_frame : int,
    frame_timer : f32,
    per_frame_time : f32,
    playing : bool,
    speed : f32,
    just_finished : bool,
    flip_x : bool,
    current_direction : Animation_Direction,
}

Animation_Direction :: enum u8 {
    SouthEast,
    East,
    NorthEast,
    North,
    NorthWest,
    West,
    SouthWest,
    South
}
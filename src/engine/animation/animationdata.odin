#+vet explicit-allocators
package animation 

import "../renderdata"
import glm "core:math/linalg"

///
/// Contains the type definitions for use throughout the animation system.
///

// Contains all the directional animation clips.
Animation_Bank :: struct {
    directional_sets : map[string][8]Animation_Clip,
}

player_anim_bank : Animation_Bank
minecart_anim_bank : Animation_Bank
goldingot_anim_bank : Animation_Bank

// Represents a frame of animation.
Animation_Frame :: struct {
    uv_min : glm.Vector2f32,
    uv_max : glm.Vector2f32,
    duration : f32,
    origin : glm.Vector2f32,
    size : glm.Vector2f32,
}

// Represents a full animation clip
Animation_Clip :: struct {
    name : string, 
    frames : []Animation_Frame,
    looping : bool,
    source_path : string,
    texture : renderdata.Texture_Handle,
}

// Used by the Animation component to run animations on the entity.
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

// Engine supports 8 isometric sprite directions
Animation_Direction :: enum u8 {
    South,
    SouthEast,
    East,
    NorthEast,
    North,
    NorthWest,
    West,
    SouthWest,
}
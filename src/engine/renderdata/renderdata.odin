package renderdata

import glm "core:math/linalg/glsl"

// #TODO: comment this 

Camera2D :: struct {
    position : glm.vec2, // world-space center of the camera
    zoom : f32, // 1 = default, 2 = zoom in, 0.5 = zoom out
    viewport_size : glm.vec2, // pixels
}

Rect2D :: struct {
    min : glm.vec2,
    max : glm.vec2,
}

Render_Pass :: enum u8 {
    World,
    UI,
    Debug,
}

// Sorting layers for entity sprites & tilemap tiles
GROUND_SORT_LAYER :: i32(0)
DEPTH_SORT_LAYER :: i32(100)
FOREGROUND_SORT_LAYER :: i32(200)

// Data for the rendered Sprite
Sprite_Instance :: struct {
    model : glm.mat4,
    // min & max are used to dictate a smaller rect for the sprite to sample from,
    // for future sprite sheets, animation, optimizations of gpu texture sending etc..
    // #TODO: Use this for animation when implemented!
    uv_min : [2]f32, 
    uv_max : [2]f32,
    color : [4]f32, // vec4
}

// Cpu side extracted draw command
Render_Item :: struct {
    pass : Render_Pass,
    sort_layer : i32,
    y_sort : f32,
    material : Material_Key,
    instance : Sprite_Instance,
}

// Range ito the uploaded instance array
Batch :: struct {
    material : Material_Key,
    pass : Render_Pass,
    first_instance : u32,
    instance_count : u32,
}

// =============== Sort & Batch Keys ===============

Texture_Handle :: distinct u32
Sampler_Handle :: distinct u32 

Default_Texture_Handle : Texture_Handle : 0
Default_Sampler_Handle : Sampler_Handle : 0

Blend_Mode :: enum u8 {
    Alpha,
    Additive, 
    Opaque,
}

Pipeline_Kind :: enum u8 {
    Sprite,
    Solid,
    Debug_Line,
}

Material_Key :: struct {
    pipeline : Pipeline_Kind,
    texture : Texture_Handle,
    sampler : Sampler_Handle,
    blend : Blend_Mode,
}

// ==============^ Sort & Batch Keys ^==============
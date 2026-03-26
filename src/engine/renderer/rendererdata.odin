package renderer

import "core:log"
import math "core:math/linalg"
import sdl "vendor:sdl3"
import glm "core:math/linalg/glsl"

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

Renderer :: struct {
    gpu : ^sdl.GPUDevice,
    window : ^sdl.Window,

    cmd_buf : ^sdl.GPUCommandBuffer,
    swapchain_tex : ^sdl.GPUTexture,
    render_pass : ^sdl.GPURenderPass,

    sprite_pipeline : ^sdl.GPUGraphicsPipeline, 

    clear_color : [4]f32,
    viewport_size : math.Vector2f32,
    camera : Camera2D,
    sprite_batcher : Sprite_Batcher,

    textures : [dynamic]Texture_Resource,
    samplers : [dynamic]Sampler_Resource,
}

// Holds the shared uniform data for the batched sprites
Sprite_Global_VS_Uniform :: struct {
    view_proj : glm.mat4 
}

Quad_Vertex :: struct {
    local_pos : [2]f32,
    uv : [2]f32,
}

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

// Holds data related to a batching of sprites.
Sprite_Batcher :: struct {
    quad_vb : ^sdl.GPUBuffer,
    quad_ib : ^sdl.GPUBuffer,

    instance_buffer : ^sdl.GPUBuffer,
    instance_transfer : ^sdl.GPUTransferBuffer,

    max_instances : u32,

    items : [dynamic]Render_Item,
    instances : [dynamic]Sprite_Instance,
    batches : [dynamic]Batch,
}

Texture_Resource :: struct {
    gpu : ^sdl.GPUTexture,
    width : u32,
    height : u32,
}

Sampler_Resource :: struct {
    gpu : ^sdl.GPUSampler,
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
package renderer

import "core:log"
import math "core:math/linalg"
import sdl "vendor:sdl3"
import glm "core:math/linalg/glsl"
import renderdata "../renderdata"

// #TODO: comment this 

Renderer :: struct {
    gpu : ^sdl.GPUDevice,
    window : ^sdl.Window,

    cmd_buf : ^sdl.GPUCommandBuffer,
    swapchain_tex : ^sdl.GPUTexture,
    render_pass : ^sdl.GPURenderPass,

    swapchain_color_format : sdl.GPUTextureFormat, // Utllized by dear_imgui render

    sprite_pipeline : ^sdl.GPUGraphicsPipeline, 

    clear_color : [4]f32,
    viewport_size : math.Vector2f32,
    camera : renderdata.Camera2D,
    sprite_batcher : Sprite_Batcher,

    textures : [dynamic]Texture_Resource,
    samplers : [dynamic]Sampler_Resource,

    batchCountThisFrame : int,
    renderedWorldElementsThisFrame : u32,  
    totalRenderedElementsThisFrame : u32,
    culledEntityElementsThisFrame : int,
    culledTilemapElementsThisFrame : int,
}

// Holds the shared uniform data for the batched sprites
Sprite_Global_VS_Uniform :: struct {
    view_proj : glm.mat4 
}

Quad_Vertex :: struct {
    local_pos : [2]f32,
    uv : [2]f32,
}

// Holds data related to a batching of sprites.
Sprite_Batcher :: struct {
    quad_vb : ^sdl.GPUBuffer,
    quad_ib : ^sdl.GPUBuffer,

    instance_buffer : ^sdl.GPUBuffer,
    instance_transfer : ^sdl.GPUTransferBuffer,

    max_instances : u32,

    items : [dynamic]renderdata.Render_Item,
    instances : [dynamic]renderdata.Sprite_Instance,
    batches : [dynamic]renderdata.Batch,
}

Texture_Resource :: struct {
    gpu : ^sdl.GPUTexture,
    width : u32,
    height : u32,
}

Sampler_Resource :: struct {
    gpu : ^sdl.GPUSampler,
}
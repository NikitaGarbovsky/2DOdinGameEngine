package renderer

import "core:log"
import math "core:math/linalg"
import sdl "vendor:sdl3"

Renderer :: struct {
    gpu : ^sdl.GPUDevice,
    window : ^sdl.Window,

    cmd_buf : ^sdl.GPUCommandBuffer,
    swapchain_tex : ^sdl.GPUTexture,
    render_pass : ^sdl.GPURenderPass,

    testing_entity_pipeline : ^sdl.GPUGraphicsPipeline,

    clear_color : [4]f32,
    viewport_size : math.Vector2f32,
}

// Holds the testing uniform data for the testing of the render pipeline (vertex shader)
Testing_VS_Uniform :: struct {
    pos : [2]f32,
    size : [2]f32,
    rot : f32, // Radians
    _pad0    : f32, // temp padding just for correct alignment when passing to shader
    view : [2]f32
}

// Holds the testing uniform data for the testing of the render pipeline (fragment shader)
Testing_FS_Uniform :: struct {
    color : [4]f32,
}
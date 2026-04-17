package renderer

import sdl "vendor:sdl3"
import "../../platform"
import "core:log"
import math "core:math/linalg"
import glm "core:math/linalg/glsl"
import "core:fmt"

// #TODO: comment this 

Init :: proc(_renderer : ^Renderer, _platform : ^platform.Platform, _vert_code, _frag_code : []u8) -> bool {
    _renderer.gpu = _platform.gpu
    _renderer.window = _platform.window
    _renderer.clear_color = {0.0, 0.2, 0.4, 1.0} // #TODO: move somewhere else

    _renderer.camera.position = glm.vec2{0,0}
    _renderer.camera.zoom = 1.0
    _renderer.camera.viewport_size = glm.vec2{1920, 1080}

    // Used by dear_imgui, set upon renderer initialization.
    _renderer.swapchain_color_format = sdl.GetGPUSwapchainTextureFormat(_renderer.gpu, _renderer.window)

    _renderer.textures = make([dynamic]Texture_Resource, 0, 64)
    _renderer.samplers = make([dynamic]Sampler_Resource, 0, 8)

    if !CreateDefaultTextureAndSampler(_renderer) do return false
    if !InitSpriteBatcher(_renderer, 65536) do return false
    if !InitSpritePipeline(_renderer, _vert_code, _frag_code) do return false

    fmt.printfln("--- Renderer Intialized Successfully.")
    return true
}

BeginFrame :: proc(_renderer : ^Renderer, viewport_size : math.Vector2f32) -> bool {
    _renderer.viewport_size = viewport_size
    _renderer.camera.viewport_size = viewport_size    

    _renderer.cmd_buf = sdl.AcquireGPUCommandBuffer(_renderer.gpu)
    if _renderer.cmd_buf == nil {
        log.errorf("AcquireGPUCommandBuffer failed: {}", sdl.GetError())
        return false
    }

    ok := sdl.WaitAndAcquireGPUSwapchainTexture(
        _renderer.cmd_buf,
        _renderer.window,
        &_renderer.swapchain_tex,
        nil,
        nil)
    if !ok {
        log.errorf("WaitAndAcquireGPUSwapchainTexture failed: {}", sdl.GetError())
        return false
    }

    if _renderer.swapchain_tex == nil {
        return false
    }

    return true
}

// The main pass of rendering all the ECS world renderable entities
BeginWorldPass :: proc(_renderer : ^Renderer) -> bool {
    if _renderer.cmd_buf == nil do return false
    if _renderer.swapchain_tex == nil do return false

    EndPass(_renderer) // End any existing passes, pre-emptive to stop crashes

    color_target := sdl.GPUColorTargetInfo{
        texture = _renderer.swapchain_tex,
        load_op = .CLEAR,
        clear_color = {
            _renderer.clear_color[0],
            _renderer.clear_color[1],
            _renderer.clear_color[2],
            _renderer.clear_color[3],
        },
        store_op = .STORE,
    }

    _renderer.render_pass = sdl.BeginGPURenderPass(_renderer.cmd_buf, &color_target, 1, nil)
    if _renderer.render_pass == nil {
        log.errorf("BeginGPURenderPass failed: {}", sdl.GetError())
        return false
    }

    return true
}

// The UI pass, used by both Editor and Gameplay GUI. 
BeginUIPass :: proc(_renderer : ^Renderer) -> ^sdl.GPURenderPass {
    if _renderer.cmd_buf == nil do return nil
    if _renderer.swapchain_tex == nil do return nil

    EndPass(_renderer) // End any existing passes, pre-emptive to stop crashes

    color_target := sdl.GPUColorTargetInfo{
        texture = _renderer.swapchain_tex,
        load_op = .LOAD,
        store_op = .STORE
    }

    pass := sdl.BeginGPURenderPass(_renderer.cmd_buf, &color_target, 1, nil)
    if pass == nil {
        log.errorf("BeginEditorUIPass failed: {}", sdl.GetError())
        return nil
    }

    _renderer.render_pass = pass
    return pass
}

EndFrame :: proc(_renderer : ^Renderer) {
    EndPass(_renderer) // End any existing passes, final step with ending the final render pass that is running.

    if _renderer.cmd_buf != nil {
        ok := sdl.SubmitGPUCommandBuffer(_renderer.cmd_buf)
        if !ok {
            log.errorf("SubmitGPUCommandBuffer failed: {}", sdl.GetError())
        }
        _renderer.cmd_buf = nil
    }

    _renderer.swapchain_tex = nil
}

// Helper to end the currently loaded renderpass
EndPass :: proc(_renderer : ^Renderer) {
    if _renderer.render_pass != nil {
        sdl.EndGPURenderPass(_renderer.render_pass) 
        _renderer.render_pass = nil
    }
}

Shutdown :: proc(_renderer : ^Renderer) {
    ShutdownSpriteBatcher(_renderer)

    if _renderer.sprite_pipeline != nil {
        sdl.ReleaseGPUGraphicsPipeline(_renderer.gpu, _renderer.sprite_pipeline)
        _renderer.sprite_pipeline = nil
    }

    for i := 0; i < len(_renderer.textures); i += 1 {
        if _renderer.textures[i].gpu != nil {
            sdl.ReleaseGPUTexture(_renderer.gpu, _renderer.textures[i].gpu)
            _renderer.textures[i].gpu = nil
        }
    }

    for i := 0; i < len(_renderer.samplers); i += 1 {
        if _renderer.samplers[i].gpu != nil {
            sdl.ReleaseGPUSampler(_renderer.gpu, _renderer.samplers[i].gpu)
            _renderer.samplers[i].gpu = nil
        }
    }

    delete(_renderer.textures)
    delete(_renderer.samplers)
}
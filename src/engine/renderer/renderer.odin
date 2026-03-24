package renderer

import sdl "vendor:sdl3"
import "../../platform"
import "core:log"
import math "core:math/linalg"
import glm "core:math/linalg/glsl"

Init :: proc(_renderer : ^Renderer, _platform : ^platform.Platform, _vert_code, _frag_code : []u8) -> bool {
    _renderer.gpu = _platform.gpu
    _renderer.window = _platform.window
    _renderer.clear_color = {0.0, 0.2, 0.4, 1.0} // #TODO: move somewhere else

    _renderer.camera.position = glm.vec2{0,0}
    _renderer.camera.zoom = 1.0
    _renderer.camera.viewport_size = glm.vec2{1920, 1080}

    if !InitSpriteBatcher(_renderer, 65536) do return false
    if !InitSpritePipeline(_renderer, _vert_code, _frag_code) do return false

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

EndFrame :: proc(_renderer : ^Renderer) {
    if _renderer.render_pass != nil {
        sdl.EndGPURenderPass(_renderer.render_pass)
        _renderer.render_pass = nil
    }

    if _renderer.cmd_buf != nil {
        ok := sdl.SubmitGPUCommandBuffer(_renderer.cmd_buf)
        if !ok {
            log.errorf("SubmitGPUCommandBuffer failed: {}", sdl.GetError())
        }
        _renderer.cmd_buf = nil
    }

    _renderer.swapchain_tex = nil
}

Shutdown :: proc(_renderer : ^Renderer) {
    ShutdownSpriteBatcher(_renderer)

    if _renderer.sprite_pipeline != nil {
        sdl.ReleaseGPUGraphicsPipeline(_renderer.gpu, _renderer.sprite_pipeline)
        _renderer.sprite_pipeline = nil
    }
}

BindMaterial :: proc(_renderer : ^Renderer, _material : Material_Key) {
    // #TODO: look up gpu texture from texture handle
    // look up the gpu sampler from sampler handle
    // bind them before the batch draw
}

UploadInstancedata :: proc(_renderer : ^Renderer, _instances : []Sprite_Instance) {
    if len(_instances) == 0 do return
    
    bytes_needed : u32 = u32(len(_instances)) * size_of(Sprite_Instance)
    assert(bytes_needed <= _renderer.sprite_batcher.max_instances * size_of(Sprite_Instance))

    mapped_raw := sdl.MapGPUTransferBuffer(_renderer.gpu, _renderer.sprite_batcher.instance_transfer, true)
    if mapped_raw == nil {
        log.errorf("MapGPUTransferBuffer instance_transfer failed: {}", sdl.GetError())
        return
    }

    mapped_instances :=([^]Sprite_Instance)(mapped_raw)
    copy(mapped_instances[:len(_instances)], _instances)

    sdl.UnmapGPUTransferBuffer(_renderer.gpu, _renderer.sprite_batcher.instance_transfer)

    copy_pass := sdl.BeginGPUCopyPass(_renderer.cmd_buf)

    src := sdl.GPUTransferBufferLocation{
        transfer_buffer = _renderer.sprite_batcher.instance_transfer,
        offset = 0,
    }

    dst := sdl.GPUBufferRegion{
        buffer = _renderer.sprite_batcher.instance_buffer,
        offset = 0,
        size = bytes_needed,
    }

    sdl.UploadToGPUBuffer(copy_pass, src, dst, true)
    sdl.EndGPUCopyPass(copy_pass)
}
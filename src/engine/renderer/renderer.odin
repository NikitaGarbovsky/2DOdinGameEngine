package renderer

import sdl "vendor:sdl3"

import "../../platform"

Renderer :: struct {
    gpu : ^sdl.GPUDevice,
    window : ^sdl.Window,
    cmd_buf : ^sdl.GPUCommandBuffer,
    swapchain : ^sdl.GPUTexture,
    pass : ^sdl.GPURenderPass,
    clear_color : [4]f32,
}

Init :: proc(_renderer : ^Renderer, _platform : ^platform.Platform) {
    _renderer.gpu = _platform.gpu
    _renderer.window = _platform.window
    _renderer.clear_color = {0.0, 0.2, 0.4, 1.0} // #TODO: move somewhere else
}

BeginFrame :: proc(_renderer : ^Renderer) -> bool {
    _renderer.cmd_buf = sdl.AcquireGPUCommandBuffer(_renderer.gpu)
    if _renderer.cmd_buf == nil do return false

    ok := sdl.WaitAndAcquireGPUSwapchainTexture(
        _renderer.cmd_buf,
        _renderer.window,
        &_renderer.swapchain,
        nil,
        nil)
    if !ok || _renderer.swapchain == nil do return false

    color_target := sdl.GPUColorTargetInfo{
        texture = _renderer.swapchain,
        load_op = .CLEAR,
        clear_color = {_renderer.clear_color[0], 
            _renderer.clear_color[1], 
            _renderer.clear_color[2], 
            _renderer.clear_color[3]},
        store_op = .STORE,
    }
    
    _renderer.pass = sdl.BeginGPURenderPass(_renderer.cmd_buf, &color_target, 1, nil)
    return _renderer.pass != nil
}

EndFrame :: proc(_renderer : ^Renderer) {
    if _renderer.pass != nil {
        sdl.EndGPURenderPass(_renderer.pass)
        _renderer.pass = nil
    }

    if _renderer.cmd_buf != nil {
        ok := sdl.SubmitGPUCommandBuffer(_renderer.cmd_buf)
        assert(ok)
        _renderer.cmd_buf = nil
    }

    _renderer.swapchain = nil
}
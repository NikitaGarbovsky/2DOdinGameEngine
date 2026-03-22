package renderer

import sdl "vendor:sdl3"
import "../../platform"
import "core:log"
import math "core:math/linalg"

Init :: proc(_renderer : ^Renderer, _platform : ^platform.Platform, _vert_code, _frag_code : []u8) -> bool {
    _renderer.gpu = _platform.gpu
    _renderer.window = _platform.window
    _renderer.clear_color = {0.0, 0.2, 0.4, 1.0} // #TODO: move somewhere else

    // Create both shader infos for vert & frag
    vert_shader_info := sdl.GPUShaderCreateInfo{
        code_size = len(_vert_code),
        code = raw_data(_vert_code),
        entrypoint = "main",
        format = {.SPIRV},
        stage = .VERTEX,
        num_samplers = 0,
        num_storage_textures = 0,
        num_storage_buffers = 0,
        num_uniform_buffers = 1,
        props = 0,
    }

    frag_shader_info := sdl.GPUShaderCreateInfo{
        code_size = len(_frag_code),
        code = raw_data(_frag_code),
        entrypoint = "main",
        format = {.SPIRV},
        stage = .FRAGMENT,
        num_samplers = 0,
        num_storage_textures = 0,
        num_storage_buffers = 0,
        num_uniform_buffers = 1,
        props = 0,
    }

    // Create both shaders
    vert_shader := sdl.CreateGPUShader(_renderer.gpu, vert_shader_info)
    if vert_shader == nil {
        log.errorf("CreateGPUShader vertex failed: {}", sdl.GetError())
        return false
    }

    frag_shader := sdl.CreateGPUShader(_renderer.gpu, frag_shader_info)
    if frag_shader == nil {
        log.errorf("CreateGPUShader fragment failed: {}", sdl.GetError())
        sdl.ReleaseGPUShader(_renderer.gpu, vert_shader)
        return false
    }

    color_target_desc := sdl.GPUColorTargetDescription{
        format = sdl.GetGPUSwapchainTextureFormat(_renderer.gpu, _renderer.window),
        blend_state = sdl.GPUColorTargetBlendState{
            enable_blend = true,
            alpha_blend_op = .ADD,
            color_blend_op = .ADD,
            src_color_blendfactor = .SRC_ALPHA,
            src_alpha_blendfactor = .SRC_ALPHA,
            dst_color_blendfactor = .ONE_MINUS_SRC_ALPHA,
            dst_alpha_blendfactor = .ONE_MINUS_SRC_ALPHA,
        },
    }

    pipeline_info := sdl.GPUGraphicsPipelineCreateInfo {
        target_info = sdl.GPUGraphicsPipelineTargetInfo{
            color_target_descriptions = &color_target_desc,
            num_color_targets = 1,
            depth_stencil_format = .INVALID,
            has_depth_stencil_target = false,
        },

        primitive_type = .TRIANGLELIST,
        vertex_shader = vert_shader,
        fragment_shader = frag_shader,
    }

    _renderer.testing_entity_pipeline = sdl.CreateGPUGraphicsPipeline(_renderer.gpu, pipeline_info)

    sdl.ReleaseGPUShader(_renderer.gpu, vert_shader)
    sdl.ReleaseGPUShader(_renderer.gpu, frag_shader)

    if _renderer.testing_entity_pipeline == nil {
        log.errorf("CreateGPUGraphicsPipeline failed: {}", sdl.GetError())
        return false
    }

    return true
}

BeginFrame :: proc(_renderer : ^Renderer, viewport_size : math.Vector2f32) -> bool {
    _renderer.viewport_size = viewport_size

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

    color_target := sdl.GPUColorTargetInfo{
        texture = _renderer.swapchain_tex,
        load_op = .CLEAR,
        clear_color = {_renderer.clear_color[0], 
            _renderer.clear_color[1], 
            _renderer.clear_color[2], 
            _renderer.clear_color[3]},
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
    if _renderer.testing_entity_pipeline != nil {
        sdl.ReleaseGPUGraphicsPipeline(_renderer.gpu, _renderer.testing_entity_pipeline)
        _renderer.testing_entity_pipeline = nil
    }
}

BindTestingPipeline :: proc (_renderer : ^Renderer) {
    if _renderer.render_pass == nil || _renderer.testing_entity_pipeline == nil do return
    sdl.BindGPUGraphicsPipeline(_renderer.render_pass, _renderer.testing_entity_pipeline)
}

DrawQuad :: proc(
    _renderer : ^Renderer,
    _pos : math.Vector2f32,
    _size : math.Vector2f32,
    _rot : f32,
    _color : [4]f32
) {
    if _renderer.render_pass == nil || _renderer.cmd_buf == nil do return

    vs_uniform := Testing_VS_Uniform {
        pos = {_pos.x, _pos.y},
        size = {_size.x, _size.y},
        rot = _rot,
        _pad0  = 0,  
        view = { _renderer.viewport_size.x, _renderer.viewport_size.y}
    }

    fs_uniform := Testing_FS_Uniform {
        color = _color,
    }

    sdl.PushGPUVertexUniformData(_renderer.cmd_buf, 0, &vs_uniform, size_of(Testing_VS_Uniform))
    sdl.PushGPUFragmentUniformData(_renderer.cmd_buf, 0, &fs_uniform, size_of(Testing_FS_Uniform))

    // 6 vertices = 2 triangles
    sdl.DrawGPUPrimitives(_renderer.render_pass, 6, 1, 0, 0)
}
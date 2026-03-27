package renderer

import sdl "vendor:sdl3"
import "core:log"
import assets "../assets"
import renderdata "../renderdata"

CreateSampler :: proc(_renderer : ^Renderer, _info : sdl.GPUSamplerCreateInfo) -> (renderdata.Sampler_Handle, bool) {
    gpu_sampler := sdl.CreateGPUSampler(_renderer.gpu, _info)
    if gpu_sampler == nil {
        log.errorf("CreateGPUSampler failed: {}", sdl.GetError())
        return renderdata.Sampler_Handle(0), false
    }

    handle := renderdata.Sampler_Handle(len(_renderer.samplers))
    append(&_renderer.samplers, Sampler_Resource{gpu = gpu_sampler})
    return handle, true
}

CreateTextureRGBA8 :: proc(_renderer : ^Renderer, _pixels : []u8, _width, _height : u32) -> (renderdata.Texture_Handle, bool) {
    expected_bytes := int(_width * _height * 4)
    if len(_pixels) != expected_bytes {
        log.errorf("CreateTextureRGBA8 invalid byte count: got {}, expected {}", len(_pixels), expected_bytes)
        return renderdata.Texture_Handle(0), false
    }

    tex := sdl.CreateGPUTexture(_renderer.gpu, sdl.GPUTextureCreateInfo{
        type = .D2,
        format = .R8G8B8A8_UNORM,
        width = _width,
        height = _height,
        layer_count_or_depth = 1,
        num_levels = 1,
        usage = {.SAMPLER},
        props = 0,
    })
    if tex == nil {
        log.errorf("CreateGPUTexture failed: {}", sdl.GetError())
        return renderdata.Texture_Handle(0), false
    }

    transfer := sdl.CreateGPUTransferBuffer(_renderer.gpu, sdl.GPUTransferBufferCreateInfo{
        usage = .UPLOAD,
        size = u32(len(_pixels)),
        props = 0,
    })
    if transfer == nil {
        log.errorf("CreateGPUTransferBuffer for texture failed: {}", sdl.GetError())
        sdl.ReleaseGPUTexture(_renderer.gpu, tex)
        return renderdata.Texture_Handle(0), false
    }

    mapped_raw := sdl.MapGPUTransferBuffer(_renderer.gpu, transfer, false)
    if mapped_raw == nil {
        log.errorf("MapGPUTransferBuffer for texture failed: {}", sdl.GetError())
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, transfer)
        sdl.ReleaseGPUTexture(_renderer.gpu, tex)
        return renderdata.Texture_Handle(0), false
    }

    mapped := ([^]u8)(mapped_raw)
    copy(mapped[:len(_pixels)], _pixels)
    sdl.UnmapGPUTransferBuffer(_renderer.gpu, transfer)

    cmd_buf := sdl.AcquireGPUCommandBuffer(_renderer.gpu)
    if cmd_buf == nil {
        log.errorf("AcquireGPUCommandBuffer for texture upload failed: {}", sdl.GetError())
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, transfer)
        sdl.ReleaseGPUTexture(_renderer.gpu, tex)
        return renderdata.Texture_Handle(0), false
    }

    copy_pass := sdl.BeginGPUCopyPass(cmd_buf)

    src := sdl.GPUTextureTransferInfo{
        transfer_buffer = transfer,
        offset = 0,
        pixels_per_row = _width,
        rows_per_layer = _height,
    }

    dst := sdl.GPUTextureRegion{
        texture = tex,
        mip_level = 0,
        layer = 0,
        x = 0,
        y = 0,
        z = 0,
        w = _width,
        h = _height,
        d = 1,
    }

    sdl.UploadToGPUTexture(copy_pass, src, dst, false)
    sdl.EndGPUCopyPass(copy_pass)

    if !sdl.SubmitGPUCommandBuffer(cmd_buf) {
        log.errorf("SubmitGPUCommandBuffer for texture upload failed: {}", sdl.GetError())
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, transfer)
        sdl.ReleaseGPUTexture(_renderer.gpu, tex)
        return renderdata.Texture_Handle(0), false
    }

    sdl.ReleaseGPUTransferBuffer(_renderer.gpu, transfer)

    handle := renderdata.Texture_Handle(len(_renderer.textures))
    append(&_renderer.textures, Texture_Resource{
        gpu = tex,
        width = _width,
        height = _height,
    })

    return handle, true
}

CreateTextureFromImage :: proc(_renderer : ^Renderer, _image : assets.Image_Data) -> (renderdata.Texture_Handle, bool) {
    if _image.format != .RGBA8 {
        log.errorf("CreateTextureFromImage only supports RGBA8 right now, dumby you forgot to remove this")
        return renderdata.Texture_Handle(0), false
    }

    if _image.width == 0 || _image.height == 0 {
        log.error("CreateTextureFromImage called with zero-sized image")
        return renderdata.Texture_Handle(0), false
    }

    if len(_image.pixels) == 0 {
        log.error("CreateTextureFromImage called with empty pixel data")
        return renderdata.Texture_Handle(0), false
    }

    expected_bytes := assets.ImageByteCount(_image)
    if len(_image.pixels) != expected_bytes {
        log.errorf(
            "CreateTextureFromImage invalid byte count: got {}, expected {}",
            len(_image.pixels),
            expected_bytes,
        )
        return renderdata.Texture_Handle(0), false
    }

    return CreateTextureRGBA8(_renderer, _image.pixels[:], _image.width, _image.height)
}

// =============== Fallbacks that I might remove at some stage as they might not be needed ===============
CreateDefaultTextureAndSampler :: proc(_renderer : ^Renderer) -> bool {
    sampler_handle, ok := CreateSampler(_renderer, sdl.GPUSamplerCreateInfo{
        min_filter = .NEAREST,
        mag_filter = .NEAREST,
        mipmap_mode = .NEAREST,
        address_mode_u = .CLAMP_TO_EDGE,
        address_mode_v = .CLAMP_TO_EDGE,
        address_mode_w = .CLAMP_TO_EDGE,
        mip_lod_bias = 0,
        max_anisotropy = 1,
        compare_op = .ALWAYS,
        min_lod = 0,
        max_lod = 0,
        enable_anisotropy = false,
        enable_compare = false,
        props = 0,
    })
    if !ok do return false
    assert(sampler_handle == renderdata.Default_Sampler_Handle)

    white := []u8{255, 255, 255, 255}
    tex_handle, ok2 := CreateTextureRGBA8(_renderer, white, 1, 1)
    if !ok2 do return false
    assert(tex_handle == renderdata.Default_Texture_Handle)

    return true
}

// Creates a placeholder texture, #TODO: might use this as a fallback if texture fails to load
CreateCheckerTexture2x2 :: proc(_renderer : ^Renderer) -> (renderdata.Texture_Handle, bool) {
    pixels := []u8{
        255,   0, 255, 255,   0,   0,   0, 255,
          0,   0,   0, 255, 255,   0, 255, 255,
    }
    return CreateTextureRGBA8(_renderer, pixels, 2, 2)
}

// =============^ Fallbacks that I might remove at some stage as they might not be needed ^=============
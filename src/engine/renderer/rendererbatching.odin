package renderer

import "core:log"
import sdl "vendor:sdl3"
import renderdata "../renderdata"
import glm "core:math/linalg"
import "core:fmt"

///
/// This file declares the full sort & batched rendering pipeline used by the renderer.
///

// Initializes the sprite pipeline, loads the shaders and preps resources for the renderer.
InitSpritePipeline :: proc(_renderer : ^Renderer, _vert_code, _frag_code : []u8) -> bool {
    
    vert_shader_info := sdl.GPUShaderCreateInfo{
        code_size            = len(_vert_code),
        code                 = raw_data(_vert_code),
        entrypoint           = "main",
        format               = {.SPIRV},
        stage                = .VERTEX,
        num_samplers         = 0,
        num_storage_textures = 0,
        num_storage_buffers  = 0,
        num_uniform_buffers  = 1,
        props                = 0,
    }

    frag_shader_info := sdl.GPUShaderCreateInfo{
        code_size            = len(_frag_code),
        code                 = raw_data(_frag_code),
        entrypoint           = "main",
        format               = {.SPIRV},
        stage                = .FRAGMENT,
        num_samplers         = 1,
        num_storage_textures = 0,
        num_storage_buffers  = 0,
        num_uniform_buffers  = 0,
        props                = 0,
    }

    vert_shader := sdl.CreateGPUShader(_renderer.gpu, vert_shader_info)
    if vert_shader == nil {
        log.errorf("CreateGPUShader sprite vertex failed: {}", sdl.GetError())
        return false
    }

    frag_shader := sdl.CreateGPUShader(_renderer.gpu, frag_shader_info)
    if frag_shader == nil {
        log.errorf("CreateGPUShader sprite fragment failed: {}", sdl.GetError())
        sdl.ReleaseGPUShader(_renderer.gpu, vert_shader)
        return false
    }

    vertex_buffer_descs := [2]sdl.GPUVertexBufferDescription{
        {
            slot               = 0,
            pitch              = u32(size_of(Quad_Vertex)),
            input_rate         = .VERTEX,
            instance_step_rate = 0,
        },
        {
            slot               = 1,
            pitch              = u32(size_of(renderdata.Sprite_Instance)),
            input_rate         = .INSTANCE,
            instance_step_rate = 0,
        },
    }

    // locations 2 - 5 are passed in as .FLOAT4's (modelmatrix), but when they reach 
    // the gpu the v shader accepts them as a single mat4, not sure why or how,
    vertex_attrs := [9]sdl.GPUVertexAttribute{
        { // Local position
            location    = 0,
            buffer_slot = 0,
            format      = .FLOAT2,
            offset      = u32(offset_of(Quad_Vertex, local_pos)),
        },
        { // UV
            location    = 1,
            buffer_slot = 0,
            format      = .FLOAT2,
            offset      = u32(offset_of(Quad_Vertex, uv)),
        },
        { // model matrix column 1
            location    = 2,
            buffer_slot = 1,
            format      = .FLOAT4,
            offset      = u32(offset_of(renderdata.Sprite_Instance, model)) + 0,
        },
        { // model matrix column 2
            location    = 3,
            buffer_slot = 1,
            format      = .FLOAT4,
            offset      = u32(offset_of(renderdata.Sprite_Instance, model)) + 16,
        },
        { // model matrix column 3
            location    = 4,
            buffer_slot = 1,
            format      = .FLOAT4,
            offset      = u32(offset_of(renderdata.Sprite_Instance, model)) + 32,
        },
        { // model matrix column 4
            location    = 5,
            buffer_slot = 1,
            format      = .FLOAT4,
            offset      = u32(offset_of(renderdata.Sprite_Instance, model)) + 48,
        },
        {
            location    = 6,
            buffer_slot = 1,
            format      = .FLOAT2,
            offset      = u32(offset_of(renderdata.Sprite_Instance, uv_min)),
        },
        {
            location    = 7,
            buffer_slot = 1,
            format      = .FLOAT2,
            offset      = u32(offset_of(renderdata.Sprite_Instance, uv_max)),
        },
        {
            location    = 8,
            buffer_slot = 1,
            format      = .FLOAT4,
            offset      = u32(offset_of(renderdata.Sprite_Instance, color)),
        },
    }

    color_target_desc := sdl.GPUColorTargetDescription{
        format = sdl.GetGPUSwapchainTextureFormat(_renderer.gpu, _renderer.window),
        blend_state = sdl.GPUColorTargetBlendState{
            src_color_blendfactor = .SRC_ALPHA,
            dst_color_blendfactor = .ONE_MINUS_SRC_ALPHA,
            color_blend_op        = .ADD,
            src_alpha_blendfactor = .SRC_ALPHA,
            dst_alpha_blendfactor = .ONE_MINUS_SRC_ALPHA,
            alpha_blend_op        = .ADD,
            enable_blend          = true,
            enable_color_write_mask = false,
        },
    }

    pipeline_info := sdl.GPUGraphicsPipelineCreateInfo{
        vertex_shader   = vert_shader,
        fragment_shader = frag_shader,

        vertex_input_state = sdl.GPUVertexInputState{
            vertex_buffer_descriptions = &vertex_buffer_descs[0],
            num_vertex_buffers         = 2,
            vertex_attributes          = &vertex_attrs[0],
            num_vertex_attributes      = len(vertex_attrs),
        },

        primitive_type = .TRIANGLELIST,

        rasterizer_state = sdl.GPURasterizerState{
            fill_mode         = .FILL,
            cull_mode         = .NONE,
            front_face        = .COUNTER_CLOCKWISE,
            enable_depth_bias = false,
            enable_depth_clip = true,
        },

        multisample_state = sdl.GPUMultisampleState{
            sample_count              = ._1,
            sample_mask               = 0,
            enable_mask               = false,
            enable_alpha_to_coverage  = false,
        },

        depth_stencil_state = sdl.GPUDepthStencilState{
            compare_op          = .ALWAYS,
            enable_depth_test   = false,
            enable_depth_write  = false,
            enable_stencil_test = false,
        },

        target_info = sdl.GPUGraphicsPipelineTargetInfo{
            color_target_descriptions = &color_target_desc,
            num_color_targets         = 1,
            depth_stencil_format      = .INVALID,
            has_depth_stencil_target  = false,
        },

        props = 0,
    }

    _renderer.sprite_pipeline = sdl.CreateGPUGraphicsPipeline(_renderer.gpu, pipeline_info)

    sdl.ReleaseGPUShader(_renderer.gpu, vert_shader)
    sdl.ReleaseGPUShader(_renderer.gpu, frag_shader)

    if _renderer.sprite_pipeline == nil {
        log.errorf("CreateGPUGraphicsPipeline sprite failed: {}", sdl.GetError())
        return false
    }

    return true
}

/// Comparison used when sorting render items before batching.
// 1. Render pass first
// 2. Then broad render layer (ground, depth-sorted world(isometric walls, player etc) atm)
// 3. For world items items only, sort by y so lower (+Y) items draw after creating depth
// 4. Finally sort by material by material so matching items can batch together.
@private
RenderItemLess :: proc(_a, _b : renderdata.Render_Item) -> bool {
    // 1.
    if _a.pass != _b.pass do return u8(_a.pass) < u8(_b.pass)
    // 2. 
    if _a.sort_layer != _b.sort_layer do return _a.sort_layer < _b.sort_layer
    // 3.
    if _a.pass == .World {
        if _a.y_sort != _b.y_sort do return _a.y_sort < _b.y_sort
    } 
    // 4.
    if _a.material.pipeline != _b.material.pipeline do return u8(_a.material.pipeline) < u8(_b.material.pipeline)
    if _a.material.blend != _b.material.blend do return u8(_a.material.blend) < u8(_b.material.blend)
    if _a.material.texture != _b.material.texture do return u32(_a.material.texture) < u32(_b.material.texture)
    if _a.material.sampler != _b.material.sampler do return u32(_a.material.sampler) < u32(_b.material.sampler)

    return false // Should not reach here.
}

@private 
SwapRenderItems :: proc(_items : []renderdata.Render_Item,i, j: int ) {
    _items[i], _items[j] = _items[j], _items[i]
}

@private 
QuickSortRenderItems :: proc(_items : []renderdata.Render_Item, lo, hi : int) {
    if lo >= hi do return

    i := lo
    j := hi
    pivot := _items[(lo + hi) / 2]

    for i <= j {
        for RenderItemLess(_items[i], pivot) do i += 1
        for RenderItemLess(pivot, _items[j]) do j -= 1

        if i <= j {
            SwapRenderItems(_items, i, j)
            i += 1
            j -= 1
        }
    }

    if lo < j do QuickSortRenderItems(_items, lo, j)
    if i < hi do QuickSortRenderItems(_items, i, hi)
}

// Used to sort the renderable items pre-batching
SortRenderItems :: proc(_items : []renderdata.Render_Item) {
    if len(_items) <= 1 do return
    QuickSortRenderItems(_items, 0, len(_items) - 1)
}

// Initializes all the resources necessary for the sprite batcher
InitSpriteBatcher :: proc(_renderer : ^Renderer, _max_instances : u32) -> bool {
    batcher := &_renderer.sprite_batcher
    batcher.max_instances = _max_instances

    batcher.items = make([dynamic]renderdata.Render_Item, 0, int(_max_instances))
    batcher.instances = make([dynamic]renderdata.Sprite_Instance, 0, int(_max_instances))
    batcher.batches = make([dynamic]renderdata.Batch, 0, 256)

    quad_vertices := [4]Quad_Vertex{
        {local_pos = {0.0, 0.0}, uv = {0.0, 0.0}},
        {local_pos = {1.0, 0.0}, uv = {1.0, 0.0}},
        {local_pos = {1.0, 1.0}, uv = {1.0, 1.0}},
        {local_pos = {0.0, 1.0}, uv = {0.0, 1.0}},
    }

    quad_indices := [6]u16{0, 1, 2, 0, 2, 3}

    quad_vb_size := u32(len(quad_vertices)) * u32(size_of(Quad_Vertex))
    quad_ib_size := u32(len(quad_indices)) * u32(size_of(u16))
    instance_buffer_size := _max_instances * u32(size_of(renderdata.Sprite_Instance))

    batcher.quad_vb = sdl.CreateGPUBuffer(_renderer.gpu, sdl.GPUBufferCreateInfo{
        usage = {.VERTEX},
        size = quad_vb_size,
        props = 0,
    })
    if batcher.quad_vb == nil {
        log.errorf("CreateGPUBuffer quad_vb failed: {}", sdl.GetError())
        return false
    }

    batcher.quad_ib = sdl.CreateGPUBuffer(_renderer.gpu, sdl.GPUBufferCreateInfo{
        usage = {.INDEX},
        size = quad_ib_size,
        props = 0,
    })
    if batcher.quad_ib == nil {
        log.errorf("CreateGPUBuffer quad_ib failed: {}", sdl.GetError())
        return false
    }

    batcher.instance_buffer = sdl.CreateGPUBuffer(_renderer.gpu, sdl.GPUBufferCreateInfo{
        usage = {.VERTEX},
        size = instance_buffer_size,
        props = 0,
    })
    if batcher.instance_buffer == nil {
        log.errorf("CreateGPUBuffer instance_buffer failed: {}", sdl.GetError())
        return false
    }

    batcher.instance_transfer = sdl.CreateGPUTransferBuffer(_renderer.gpu, sdl.GPUTransferBufferCreateInfo{
        usage = .UPLOAD,
        size = instance_buffer_size,
        props = 0,
    })
    if batcher.instance_transfer == nil {
        log.errorf("CreateGPUTransferBuffer instance_transfer failed: {}", sdl.GetError())
        return false
    }

    // ============= Temporary upload buffers for one-time static quad geometry upload =============
    quad_vb_transfer := sdl.CreateGPUTransferBuffer(_renderer.gpu, sdl.GPUTransferBufferCreateInfo{
        usage = .UPLOAD,
        size = quad_vb_size,
        props = 0,
    })
    if quad_vb_transfer == nil {
        log.errorf("CreateGPUTransferBuffer quad_vb_transfer failed: {}", sdl.GetError())
        return false
    }

    quad_ib_transfer := sdl.CreateGPUTransferBuffer(_renderer.gpu, sdl.GPUTransferBufferCreateInfo{
        usage = .UPLOAD,
        size = quad_ib_size,
        props = 0,
    })
    if quad_ib_transfer == nil {
        log.errorf("CreateGPUTransferBuffer quad_ib_transfer failed: {}", sdl.GetError())
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, quad_vb_transfer)
        return false
    }

    // Fill quad vertex transfer buffer
    mapped_vb_raw := sdl.MapGPUTransferBuffer(_renderer.gpu, quad_vb_transfer, false)
    if mapped_vb_raw == nil {
        log.errorf("MapGPUTransferBuffer quad_vb_transfer failed: {}", sdl.GetError())
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, quad_vb_transfer)
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, quad_ib_transfer)
        return false
    }
    mapped_vb := ([^]Quad_Vertex)(mapped_vb_raw)
    copy(mapped_vb[:len(quad_vertices)], quad_vertices[:])
    sdl.UnmapGPUTransferBuffer(_renderer.gpu, quad_vb_transfer)

    // Fill quad index transfer buffer
    mapped_ib_raw := sdl.MapGPUTransferBuffer(_renderer.gpu, quad_ib_transfer, false)
    if mapped_ib_raw == nil {
        log.errorf("MapGPUTransferBuffer quad_ib_transfer failed: {}", sdl.GetError())
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, quad_vb_transfer)
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, quad_ib_transfer)
        return false
    }
    mapped_ib := ([^]u16)(mapped_ib_raw)
    copy(mapped_ib[:len(quad_indices)], quad_indices[:])
    sdl.UnmapGPUTransferBuffer(_renderer.gpu, quad_ib_transfer)

    cmd_buf := sdl.AcquireGPUCommandBuffer(_renderer.gpu)
    if cmd_buf == nil {
        log.errorf("AcquireGPUCommandBuffer for sprite batcher init failed: {}", sdl.GetError())
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, quad_vb_transfer)
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, quad_ib_transfer)
        return false
    }

    copy_pass := sdl.BeginGPUCopyPass(cmd_buf)

    vb_src := sdl.GPUTransferBufferLocation{
        transfer_buffer = quad_vb_transfer,
        offset = 0,
    }
    vb_dst := sdl.GPUBufferRegion{
        buffer = batcher.quad_vb,
        offset = 0,
        size = quad_vb_size,
    }
    sdl.UploadToGPUBuffer(copy_pass, vb_src, vb_dst, false)

    ib_src := sdl.GPUTransferBufferLocation{
        transfer_buffer = quad_ib_transfer,
        offset = 0,
    }
    ib_dst := sdl.GPUBufferRegion{
        buffer = batcher.quad_ib,
        offset = 0,
        size = quad_ib_size,
    }
    sdl.UploadToGPUBuffer(copy_pass, ib_src, ib_dst, false)

    sdl.EndGPUCopyPass(copy_pass)

    ok := sdl.SubmitGPUCommandBuffer(cmd_buf)
    if !ok {
        log.errorf("SubmitGPUCommandBuffer for sprite batcher init failed: {}", sdl.GetError())
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, quad_vb_transfer)
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, quad_ib_transfer)
        return false
    }

    sdl.ReleaseGPUTransferBuffer(_renderer.gpu, quad_vb_transfer)
    sdl.ReleaseGPUTransferBuffer(_renderer.gpu, quad_ib_transfer)

    return true
}

// Builds the batches of renderable items
BuildBatches :: proc(
    _renderer : ^Renderer, 
    _renderItems : []renderdata.Render_Item,
    _outInstances : ^[dynamic]renderdata.Sprite_Instance, 
    _outBatches : ^[dynamic]renderdata.Batch
) {
    clear(_outInstances)
    clear(_outBatches)

    if len(_renderItems) == 0 do return

    current_material := _renderItems[0].material
    current_pass := _renderItems[0].pass
    first_instance : u32 = 0
    count : u32 = 0

    for item in _renderItems {
        same_batch := item.pass == current_pass && item.material == current_material

        if !same_batch {
            append(_outBatches, renderdata.Batch{
                material = current_material,
                pass = current_pass,
                first_instance = first_instance,
                instance_count = count,
            })

            current_material = item.material
            current_pass = item.pass
            first_instance = u32(len(_outInstances))
            count = 0
        }

        append(_outInstances, item.instance)
        count += 1
    }

    append(_outBatches, renderdata.Batch{
        material = current_material,
        pass = current_pass,
        first_instance = first_instance,
        instance_count = count,
    })
}



// Sents all the batched render data to the gpu.
SubmitRenderBatches :: proc(
    _renderer : ^Renderer,
    _batches : []renderdata.Batch,
    _view_proj : glm.Matrix4f32,
) {
    if _renderer.render_pass == nil do return
    if _renderer.sprite_pipeline == nil do return
    if len(_batches) == 0 do return

    global_vs := Sprite_Global_VS_Uniform{
        view_proj = _view_proj,
    }

    sdl.PushGPUVertexUniformData(
        _renderer.cmd_buf,
        0,
        &global_vs,
        u32(size_of(Sprite_Global_VS_Uniform)),
    )

    sdl.BindGPUGraphicsPipeline(_renderer.render_pass, _renderer.sprite_pipeline)

    vb_bindings := [2]sdl.GPUBufferBinding{
        {buffer = _renderer.sprite_batcher.quad_vb, offset = 0},
        {buffer = _renderer.sprite_batcher.instance_buffer, offset = 0},
    }
    sdl.BindGPUVertexBuffers(_renderer.render_pass, 0, &vb_bindings[0], 2)

    ib_binding := sdl.GPUBufferBinding{
        buffer = _renderer.sprite_batcher.quad_ib,
        offset = 0,
    }
    sdl.BindGPUIndexBuffer(_renderer.render_pass, ib_binding, ._16BIT)

    current_material : renderdata.Material_Key
    first := true

    for batch in _batches {
        if first || batch.material != current_material {
            BindMaterial(_renderer, batch.material)
            current_material = batch.material
            first = false
        }

        sdl.DrawGPUIndexedPrimitives(
            _renderer.render_pass,
            6,
            batch.instance_count,
            0,
            0,
            batch.first_instance,
        )
    }

    // ============= Debug info for the editor =============
    _renderer.batchCountThisFrame = len(_batches)
    totalRenderCount : u32 
    world_instance_count : u32
    for batch in _batches {
        totalRenderCount += batch.instance_count
        if batch.pass == .World {
            world_instance_count += batch.instance_count
        }
    }
    _renderer.renderedWorldElementsThisFrame = world_instance_count
    _renderer.totalRenderedElementsThisFrame = totalRenderCount
}

// Helper to look up the material resource and binds them (before the batch draw)
BindMaterial :: proc(_renderer : ^Renderer, _material : renderdata.Material_Key) {
    tex_index := int(_material.texture)
    samp_index := int(_material.sampler)

    if tex_index < 0 || tex_index >= len(_renderer.textures) {
        tex_index = int(renderdata.Default_Texture_Handle)
    }
    if samp_index < 0 || samp_index >= len(_renderer.samplers) {
        samp_index = int(renderdata.Default_Sampler_Handle)
    }

    binding := sdl.GPUTextureSamplerBinding{
        texture = _renderer.textures[tex_index].gpu,
        sampler = _renderer.samplers[samp_index].gpu,
    }

    sdl.BindGPUFragmentSamplers(_renderer.render_pass, 0, & binding, 1)
}

// Uploads all the sprite instances to the gpu that are due to be renderered, asynchronously (on gpu)
UploadInstancedata :: proc(_renderer : ^Renderer, _instances : []renderdata.Sprite_Instance) {
    if len(_instances) == 0 do return

    bytes_needed : u32 = u32(len(_instances)) * size_of(renderdata.Sprite_Instance)
    assert(bytes_needed <= _renderer.sprite_batcher.max_instances * size_of(renderdata.Sprite_Instance))

    mapped_raw := sdl.MapGPUTransferBuffer(_renderer.gpu, _renderer.sprite_batcher.instance_transfer, true)
    if mapped_raw == nil {
        log.errorf("MapGPUTransferBuffer instance_transfer failed: {}", sdl.GetError())
        return
    }

    mapped_instances :=([^]renderdata.Sprite_Instance)(mapped_raw)
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

ShutdownSpriteBatcher :: proc(_renderer : ^Renderer) {
    batcher := &_renderer.sprite_batcher

    if batcher.quad_vb != nil {
        sdl.ReleaseGPUBuffer(_renderer.gpu, batcher.quad_vb)
        batcher.quad_vb = nil
    }

    if batcher.quad_ib != nil {
        sdl.ReleaseGPUBuffer(_renderer.gpu, batcher.quad_ib)
        batcher.quad_ib = nil
    }

    if batcher.instance_buffer != nil {
        sdl.ReleaseGPUBuffer(_renderer.gpu, batcher.instance_buffer)
        batcher.instance_buffer = nil
    }

    if batcher.instance_transfer != nil {
        sdl.ReleaseGPUTransferBuffer(_renderer.gpu, batcher.instance_transfer)
        batcher.instance_transfer = nil
    }

    delete(batcher.items)
    delete(batcher.instances)
    delete(batcher.batches)
}

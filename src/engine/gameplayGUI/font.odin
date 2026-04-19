#+vet explicit-allocators
package gameplaygui

import "vendor:sdl3/ttf"
import sdl "vendor:sdl3"
import "../renderer"
import "core:log"
import "core:strings"
import "../renderdata"

///
/// Manages the loading and preparing of ttf files for rendering text in the UI
/// pass of the batched sprite renderer. 
///



// Loads the font, creates the atlas resources, and prepares the glyph cache.
InitFontAtlas :: proc(
    _renderer : ^renderer.Renderer,
    _atlas : ^Font_Atlas,
    _font_path : string,
    _pt_size : f32,
    _atlas_w, _atlas_h : int,
) -> bool {
    // Make sure the font library is ready before loading any fonts,
    if ttf.WasInit() == 0{
        if !ttf.Init() {
            log.errorf("TTF_Init failed: {}", sdl.GetError())
            return false
        }
    }

    // Load the ttf file
    text_c := strings.clone_to_cstring(_font_path, context.temp_allocator)
    _atlas.font = ttf.OpenFont(text_c, _pt_size)
    if _atlas.font == nil {
        log.errorf("TTF_OpenFont failed: {}", sdl.GetError())
        return false
    }

    // Initialize the atlas size, packing state, and CPU-side storage,
    _atlas.width = _atlas_w
    _atlas.height = _atlas_h
    _atlas.next_x = 0
    _atlas.next_y = 0
    _atlas.row_height = 0
    _atlas.dirty = false

    _atlas.pixels = make([]u8, _atlas.width * _atlas.height * 4)
    _atlas.glyphs = make(map[rune]Font_Glyph)

    // Create the GPU resources used to render glyphs from the atlas.
    tex, ok := renderer.CreateTextureRGBA8(
        _renderer,
        _atlas.pixels,
        u32(_atlas.width),
        u32(_atlas.height),
    )
    if !ok {
        log.error("Failed to create font atlas texture")
        return false
    }

    samp, ok2 := renderer.CreateSampler(_renderer, sdl.GPUSamplerCreateInfo{
        min_filter = .LINEAR,
        mag_filter = .LINEAR,
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
    if !ok2 {
        log.error("Failed to create font atlas sampler")
        return false
    }

    _atlas.texture = tex
    _atlas.sampler = samp

    return true
}

// Find space in the atlas for a new glyph
AtlasInsert :: proc(_atlas : ^Font_Atlas, _w, _h : int) -> (x, y : int, ok : bool) {
    padding := 1

    if _atlas.next_x + _w + padding > _atlas.width {
        _atlas.next_x = 0
        _atlas.next_y += _atlas.row_height + padding
        _atlas.row_height = 0
    }

    if _atlas.next_y + _h + padding > _atlas.height {
        return 0, 0, false
    }

    x = _atlas.next_x
    y = _atlas.next_y

    _atlas.next_x += _w + padding
    if _h > _atlas.row_height do _atlas.row_height = _h

    return x, y, true
}

// Copy a rasterized glyph surface into the CPU-side atlas buffer.
CopyGlyphSurfaceIntoAtlasRGBA8 :: proc(
    _atlas : ^Font_Atlas,
    _dst_x, _dst_y : int,
    _surf : ^sdl.Surface,
) {
    src_w := int(_surf.w)
    src_h := int(_surf.h)
    src_pitch := int(_surf.pitch)

    src_bytes := ([^]u8)(_surf.pixels)

    for y := 0; y < src_h; y += 1 {
        src_row := src_bytes[y * src_pitch:]
        dst_row_start := ((_dst_y + y) * _atlas.width + _dst_x) * 4

        for x := 0; x < src_w; x += 1 {
            src_i := x * 4
            dst_i := dst_row_start + x * 4

            _atlas.pixels[dst_i + 0] = src_row[src_i + 0]
            _atlas.pixels[dst_i + 1] = src_row[src_i + 1]
            _atlas.pixels[dst_i + 2] = src_row[src_i + 2]
            _atlas.pixels[dst_i + 3] = src_row[src_i + 3]
        }
    }
}

// Load a glyph into the atlas the first time it is needed, then cache it.
EnsureGlyphLoaded :: proc(_atlas : ^Font_Atlas, _ch : rune) -> (Font_Glyph, bool) {
    // Already cached?
    if glyph, ok := _atlas.glyphs[_ch]; ok && glyph.loaded {
        return glyph, true
    }

    if _atlas.font == nil {
        return Font_Glyph{}, false
    }

    requested_ch := _ch
    raster_ch := _ch

    // Use ? if the font does not contain the requested character.
    if !ttf.FontHasGlyph(_atlas.font, u32(raster_ch)) {
        raster_ch = '?'
        if !ttf.FontHasGlyph(_atlas.font, u32(raster_ch)) {
            return Font_Glyph{}, false
        }
    }

    // Read the glyph data from the font,
    minx, maxx, miny, maxy, advance : i32
    if !ttf.GetGlyphMetrics(
        _atlas.font,
        u32(raster_ch),
        &minx,
        &maxx,
        &miny,
        &maxy,
        &advance,
    ) {
        return Font_Glyph{}, false
    }

    // and rasterize it into a temporary surface.
    white := sdl.Color{255, 255, 255, 255}
    surf := ttf.RenderGlyph_Blended(_atlas.font, u32(raster_ch), white)
    if surf == nil {
        return Font_Glyph{}, false
    }
    defer sdl.DestroySurface(surf)

    glyph_w := int(surf.w)
    glyph_h := int(surf.h)

    // Reserve atlas space for the glyph and copy its pixels into the atlas.
    dst_x, dst_y, ok := AtlasInsert(_atlas, glyph_w, glyph_h)
    if !ok {
        return Font_Glyph{}, false
    }
    CopyGlyphSurfaceIntoAtlasRGBA8(_atlas, dst_x, dst_y, surf)

    // Store the glyph’s atlas position, UVs, size, and spacing data.
    glyph := Font_Glyph{
        loaded = true,
        codepoint = raster_ch,

        atlas_px = {dst_x, dst_y},
        size_px = {glyph_w, glyph_h},

        uv_min = {
            f32(dst_x) / f32(_atlas.width),
            f32(dst_y) / f32(_atlas.height),
        },
        uv_max = {
            f32(dst_x + glyph_w) / f32(_atlas.width),
            f32(dst_y + glyph_h) / f32(_atlas.height),
        },
        
        advance_x = advance,
    }

    // Cache under the originally requested codepoint,
    _atlas.glyphs[requested_ch] = glyph
    // Mark the atlas so it gets uploaded to the GPU again (for reloading during runtime)
    _atlas.dirty = true

    return glyph, true
}

// Reupload the font atlas if it's detected as changed.
UploadFontAtlasIfDirty :: proc(
    _renderer : ^renderer.Renderer,
    _atlas : ^Font_Atlas,
) -> bool {
    if !_atlas.dirty do return true
    if _atlas.texture == renderdata.Texture_Handle(0) do return false

    ok := renderer.UpdateTextureRGBA8(
        _renderer,
        _atlas.texture,
        _atlas.pixels,
        u32(_atlas.width),
        u32(_atlas.height),
    )
    if ok {
        _atlas.dirty = false
    }
    return ok
}

// Free the font atlas resources and reset its state.
ShutdownFontAtlas :: proc(_atlas : ^Font_Atlas) {
    if _atlas.font != nil {
        ttf.CloseFont(_atlas.font)
        _atlas.font = nil
    }

    if len(_atlas.pixels) > 0 {
        delete(_atlas.pixels)
        _atlas.pixels = nil 
    }

    if len(_atlas.glyphs) > 0 {
        delete(_atlas.glyphs)
    }

    _atlas.width = 0
    _atlas.height = 0
    _atlas.next_x = 0
    _atlas.next_y = 0
    _atlas.row_height = 0
    _atlas.dirty = false
}

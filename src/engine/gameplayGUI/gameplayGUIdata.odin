package gameplaygui

import clay "Dependencies:clay/clay-odin"
import "vendor:sdl3/ttf"
import "../renderdata"

///
/// Data decleration file containing the gameplay GUI and font object structs
///


// Holds the state and resources for the clay ui layouting system
Clay_UI :: struct {
    initialized : bool,
    clay_ctx: ^clay.Context,
    arena_mem : []u8,

    gameplay_font : Font_Atlas,
}

// Holds all the font data that is loaded from the ttf file
Font_Atlas :: struct {
    font : ^ttf.Font,
    texture : renderdata.Texture_Handle,
    sampler : renderdata.Sampler_Handle,

    width : int,
    height : int,

    next_x : int,
    next_y : int,
    row_height : int,
    dirty : bool,

    // CPU-side RGBA8 atlas pixels
    pixels : []u8,
    glyphs : map[rune]Font_Glyph,
}

// Holds the data for a loaded glyph from a ttf font file
Font_Glyph :: struct {
    loaded : bool,
    codepoint : rune,

    atlas_px : [2]int, // Top-left in atlas pixels
    size_px : [2]int,

    uv_min : [2]f32,
    uv_max : [2]f32,

    advance_x : i32,
}
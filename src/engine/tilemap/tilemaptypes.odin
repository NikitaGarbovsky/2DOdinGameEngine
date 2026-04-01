package tilemap

import sdl "vendor:sdl3"
import "core:sync"
import "../renderdata"

///
/// Contains all the definitions of tilemap types
///


Tilemap :: struct {
    tiles : map[Tile_Coord]Tile_Instance,
}

Tile_Def_ID :: distinct u32

// When creating a tile, define a bunch of properties about it to reference
Tile_Definition :: struct {
    id : Tile_Def_ID,
    key : string,

    texture : renderdata.Texture_Handle,
    sampler : renderdata.Sampler_Handle,

    uv_min : [2]f32,
    uv_max : [2]f32,

    size : [2]f32,
    origin : [2]f32,

    layer : i32,

    collision : Collision_Kind
}

Tile_Instance :: struct {
    def_id : Tile_Def_ID,
}

Tile_Def_Library :: struct {
    defs : [dynamic]Tile_Definition,
    id_by_key : map[string]Tile_Def_ID,
}

Tile_Coord :: struct {
    x : i32,
    y : i32,
}

// #TODO: Use when implementing tile collision.
Collision_Kind :: enum u8 {
    None,
    Full_Diamond,
    Polygon,
}

Level_State :: struct {
    defsLibrary : Tile_Def_Library,
    tmap : Tilemap,
    editor : Tilemap_Editor_State,
}

Tile_Palette_Group :: enum u8 {
    Ground,
    Walls,
    Props,
    Details,
}

Tile_Source_Rect_Px :: struct {
    x, y : i32,
    w, h : i32,
}

Palette_Item :: struct {
    def_id : Tile_Def_ID,
    label : string,

    group : Tile_Palette_Group,

    src_px : Tile_Source_Rect_Px,
    preview_px : [2]f32,
}

Tilemap_Editor_State :: struct {
    enabled : bool,
    mode : Edit_Mode,

    selected_tile : Tile_Def_ID,
    has_selected_tile : bool,

    hovered_cell : Tile_Coord, 
    has_hovered_cell : bool,

    tile_w : f32,
    tile_h : f32,

    show_grid : bool,
    grid_sort_layer : i32,
    grid_thickness : f32,
    grid_color : [4]f32,
    hover_color : [4]f32,
    preview_color : [4]f32,

    // Palette UI
    palette_open : bool,
    selected_group : Tile_Palette_Group,
    palette_items : [dynamic]Palette_Item,
    palette_texture : renderdata.Texture_Handle,

    // For ImGui 1.91.9 SDLGPU3 backend, used by the tielmap editor
    palette_texture_binding : sdl.GPUTextureSamplerBinding,
    palette_texture_imgui_id : rawptr,

    palette_thumb_size : f32,
    palette_window_size : [2]f32,

    origin_edit_value : [2]f32,
    origin_edit_loaded : bool,
    origin_edit_loaded_for : Tile_Def_ID,

    tileset_meta_path : string,

    current_level_path : Path_Buffer,
    pending_load_path : Path_Buffer,
    has_pending_load_path : bool,
    dialog_mutex : sync.Mutex,

    pending_save_path : Path_Buffer,
    has_pending_save_path : bool,
}

Edit_Mode :: enum u8 {
    Paint, 
    Delete,
}

MAX_LEVEL_PATH_BYTES :: 1024

Path_Buffer :: struct {
    len : int,
    buf : [MAX_LEVEL_PATH_BYTES]u8,
}

Hardcoded_Palette_Tile :: struct {
    key : string,
    label : string,
    group : Tile_Palette_Group,

    src_px : Tile_Source_Rect_Px,

    world_size : [2]f32,
    origin : [2]f32,
}

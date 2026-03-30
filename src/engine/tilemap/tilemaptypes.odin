package tilemap

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
    defs : Tile_Def_Library,
    tmap : Tilemap,
    editor : Tilemap_Editor_State,
}

// #TODO: use this when implementing the tilemap editor
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
}

Edit_Mode :: enum u8 {
    Paint, 
    Delete,
}


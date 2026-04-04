package tilemap

import "../renderdata"
import sdl "vendor:sdl3"
import "../renderer"

///
/// Manages initialization and shutdown of the tilemap level
///



// Initializes the resources and base configuration for the Level.
InitLevelState :: proc(_level : ^Level_State, _tile_w, _tile_h : f32) {
    InitTileDefLibrary(&_level.defsLibrary)
    for i := 0; i < TILEMAP_LAYER_COUNT; i += 1 {
        InitTilemap(&_level.tmaps[i])
    }

    _level.resources.tile_w = _tile_w
    _level.resources.tile_h = _tile_h

    _level.resources.tileset_texture = renderdata.Texture_Handle(0)
    _level.resources.tileset_meta_path = ""
}

// Initializes editor state when using the tilemap editor.
InitLevelEditorState :: proc(
    _level : ^Level_State,
    _renderer : ^renderer.Renderer,
)
{
    _level.editor.enabled = true
    _level.editor.mode = .Paint
    _level.editor.has_selected_tile = false
    _level.editor.has_hovered_cell = false

    // #TODO: make these all configurable in editor
    _level.editor.show_grid = true
    _level.editor.grid_sort_layer = 1
    _level.editor.grid_thickness = 0.5
    _level.editor.grid_color = {1, 1, 1, 0.1}
    _level.editor.hover_color = {1, 1, 0.8, 0.75}
    _level.editor.hover_delete_color = {1.0, 0.35, 0.35, 0.85}
    _level.editor.preview_color = {0.7, 1.0, 1.0, 0.45}

    _level.editor.palette_open = false
    _level.editor.selected_group = .Ground
    _level.editor.palette_texture_binding = sdl.GPUTextureSamplerBinding{}
    _level.editor.palette_texture_imgui_id = nil

    _level.editor.origin_edit_value = {0.5, 0.5}
    _level.editor.origin_edit_loaded = false
    _level.editor.origin_edit_loaded_for = Tile_Def_ID(0)

    _level.editor.palette_items = nil

    //_level.editor.current_level_path.len = 0
    _level.editor.pending_load_path.len = 0
    _level.editor.has_pending_load_path = false
    _level.editor.pending_save_path.len = 0
    _level.editor.has_pending_save_path = false

    InitEditorPallete_Cave(_level, _renderer)
}

ShutdownLevelEditorState :: proc(_level : ^Level_State) {
    _level.editor.enabled = false
    _level.editor.palette_open = false
    _level.editor.has_selected_tile = false
    _level.editor.has_hovered_cell = false

    _level.editor.palette_texture_binding = sdl.GPUTextureSamplerBinding{}
    _level.editor.palette_texture_imgui_id = nil

    if _level.editor.palette_items != nil {
        delete(_level.editor.palette_items)
        _level.editor.palette_items = nil
    }

    // #TODO: maybe want to give editor option at some point to wipe editor level between editor swaps.
    //_level.editor.current_level_path.len = 0 
    _level.editor.pending_load_path.len = 0
    _level.editor.has_pending_load_path = false
    _level.editor.pending_save_path.len = 0
    _level.editor.has_pending_save_path = false
}

DestroyLevelState :: proc(_level : ^Level_State) {
    for i := 0; i < TILEMAP_LAYER_COUNT; i += 1 {
        DestroyTilemap(&_level.tmaps[i])
    }
    DestroyTileDefLibrary(&_level.defsLibrary)
    
    if cap(_level.editor.palette_items) > 0 {
        delete(_level.editor.palette_items)
    }
}

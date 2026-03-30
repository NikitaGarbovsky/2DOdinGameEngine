package tilemap

///
/// Manages initialization and shutdown of the tilemap level
///



// Initializes everthing todo with the level/tilemap
InitLevelState :: proc(_level : ^Level_State, _tile_w, _tile_h : f32) {
    InitTileDefLibrary(&_level.defs)
    InitTilemap(&_level.tmap)

    _level.editor.enabled = true
    _level.editor.mode = .Paint
    _level.editor.has_selected_tile = false
    _level.editor.has_hovered_cell = false
    _level.editor.tile_w = _tile_w
    _level.editor.tile_h = _tile_h

    // #TODO: make these all configurable in editor
    _level.editor.show_grid = true
    _level.editor.grid_sort_layer = 1
    _level.editor.grid_thickness = 0.5
    _level.editor.grid_color = {1, 1, 1, 0.1}
    _level.editor.hover_color = {1, 1, 0.8, 0.75}
    _level.editor.preview_color = {0.7, 1.0, 1.0, 0.45}
}

DestroyLevelState :: proc(_level : ^Level_State) {
    DestroyTilemap(&_level.tmap)
    DestroyTileDefLibrary(&_level.defs)
}

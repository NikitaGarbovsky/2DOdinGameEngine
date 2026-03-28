package tilemap

// Initializes everthing todo with the level/tilemap
InitLevelState :: proc(_level : ^Level_State, _tile_w, _tile_h : f32) {
    InitTileDefLibrary(&_level.defs)
    InitTilemap(&_level.tmap)

    _level.editor.enabled = false
    _level.editor.mode = .Paint
    _level.editor.has_selected_tile = false
    _level.editor.has_hovered_cell = false
    _level.editor.tile_w = _tile_w
    _level.editor.tile_h = _tile_h
}

DestroyLevelState :: proc(_level : ^Level_State) {
    DestroyTilemap(&_level.tmap)
    DestroyTileDefLibrary(&_level.defs)
}

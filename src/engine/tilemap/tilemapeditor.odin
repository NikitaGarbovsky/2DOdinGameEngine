package tilemap

import "../renderdata"

///
/// Manages the editing functionality of the tilemap.
///


// Object containing editor tilemap input state
Tilemap_Editor_Input :: struct {
    mouse_screen : [2]f32,
    left_clicked : bool, 
    delete_pressed : bool,
}


// Sets the specific tile based of ID to paint onto the tilemap
SelectTileForPainting :: proc(_level : ^Level_State, _def_id : Tile_Def_ID) {
    _level.editor.selected_tile = _def_id
    _level.editor.has_selected_tile = true
    _level.editor.mode = .Paint
}

// Per frame update (hover ghost pos, delete outline pos, tilemap painting interaction pos)
UpdateEditor :: proc(
    _level: ^Level_State,
    _cam: ^renderdata.Camera2D,
    _input: Tilemap_Editor_Input,
) {
    if !_level.editor.enabled {
        _level.editor.has_hovered_cell = false
        return
    }

    world_pos := renderdata.ScreenToWorldPos(_cam, _input.mouse_screen)
    hovered := WorldToIsoGridCoordinate(world_pos, _level.editor.tile_w, _level.editor.tile_h)

    _level.editor.hovered_cell = hovered
    _level.editor.has_hovered_cell = true

    if _input.delete_pressed {
        if _level.editor.mode == .Delete {
            _level.editor.mode = .Paint
        } else {
            _level.editor.mode = .Delete
        }
    }

    if _input.left_clicked {
        switch _level.editor.mode {
        case .Paint:
            if _level.editor.has_selected_tile {
                PlaceTile(&_level.tmap, hovered, _level.editor.selected_tile)
            }

        case .Delete:
            RemoveTile(&_level.tmap, hovered)
        }
    }
}
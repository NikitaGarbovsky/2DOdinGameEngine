package tilemap 

import "core:fmt"

///
/// Manages storing, mutating and registering tiles on the tilemap
/// 


InitTilemap :: proc(_tmap : ^Tilemap) {
    _tmap.tiles = make(map[Tile_Coord]Tile_Instance) 
}

// #TODO: Use these helpers when creating the tile palete UI.
InitTileDefLibrary :: proc(_lib : ^Tile_Def_Library) {
    _lib.defs = make([dynamic]Tile_Definition)
    _lib.id_by_key = make(map[string]Tile_Def_ID)
}

DestroyTileDefLibrary :: proc (_lib : ^Tile_Def_Library) {
    if len(_lib.defs) > 0 {
        delete(_lib.defs)
    }
    if len(_lib.id_by_key) > 0 {
        delete(_lib.id_by_key)
    }
}

DestroyTilemap :: proc(_map : ^Tilemap) {
    if len(_map.tiles) > 0 {
        delete(_map.tiles)
    }
}

// Used when creating a new tile
RegisterTileDef :: proc(_lib : ^Tile_Def_Library, _def : ^Tile_Definition) -> Tile_Def_ID {
    // Don't allow tiles with the same key. #TODO: when implementing this in editor, don't allow the
    // user to do this, instead of crashing the program here.
    if _, exists := _lib.id_by_key[_def.key]; exists {
        panic(fmt.aprintf("RegisterTileDef: duplicate key '%s'", _def.key))
    }

    new_id := Tile_Def_ID(len(_lib.defs))
    _def.id = new_id

    append(&_lib.defs, _def^)
    _lib.id_by_key[_def.key] = new_id

    return new_id
}

GetTileDef :: proc(_lib : ^Tile_Def_Library, _id : Tile_Def_ID) -> (^Tile_Definition, bool) {
    idx := int(_id)
    if idx < 0 || idx >= len(_lib.defs) {
        return nil, false
    }

    return &_lib.defs[idx], true
}

FindTileDefByKey :: proc(_lib : ^Tile_Def_Library, _key : string) -> (Tile_Def_ID, bool) {
    id, ok := _lib.id_by_key[_key]
    return id, ok
}

PlaceTile :: proc(_tmap : ^Tilemap, _cell : Tile_Coord, _def_id : Tile_Def_ID) {
    _tmap.tiles[_cell] = Tile_Instance{def_id = _def_id}
}

RemoveTile :: proc(_tmap : ^Tilemap, _cell : Tile_Coord) {
    delete_key(&_tmap.tiles, _cell)
}

GetTile :: proc(_tmap : ^Tilemap, _cell : Tile_Coord) -> (Tile_Instance, bool) {
    tile, ok := _tmap.tiles[_cell]
    return tile, ok
}

HasTile :: proc(_tmap : ^Tilemap, _cell : Tile_Coord) -> bool {
    _, ok := _tmap.tiles[_cell]
    return ok
}

ClearTilemap :: proc(_tmap : ^Tilemap) {
    for cell in _tmap.tiles {
        delete_key(&_tmap.tiles, cell)
    }
}

GetTilemapForLayer :: proc(_level : ^Level_State, _layer : Tilemap_Layer) -> ^Tilemap {
    return &_level.tmaps[int(_layer)]
}

GetSelectedEditorTilemap :: proc(_level : ^Level_State) -> ^Tilemap {
    return GetTilemapForLayer(_level, _level.editor.selected_layer)
}

ClearAllTileLayers :: proc(_level : ^Level_State) {
    for i := 0; i < TILEMAP_LAYER_COUNT; i += 1 {
        ClearTilemap(&_level.tmaps[i])
    }
}

TilemapLayerLabel :: proc(_layer : Tilemap_Layer) -> cstring {
    switch _layer {
    case .Ground : return "Ground"
    case .Walls : return "Walls"
    case .Decoration : return "Decorations"
    }
    return "Unknown"
}

TilemapLayerName :: proc(_layer : Tilemap_Layer) -> string {
    switch _layer {
    case .Ground : return "ground"
    case .Walls : return "walls"
    case .Decoration : return "decorations"
    }
    return "unknown"
}

TilemapLayerFromName :: proc(_name : string) -> (Tilemap_Layer, bool) {
    switch _name {
    case "ground" : return .Ground, true
    case "walls" : return .Walls, true
    case "decorations" : return .Decoration, true
    }
    return .Ground, false
}
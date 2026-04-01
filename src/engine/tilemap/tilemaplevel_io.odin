package tilemap

import "../leveldata"
import "core:log"
import "core:slice"

/// Manages transforming the tilemap grid data to level data to save it.


PathBuffer_Set :: proc(_buf : ^Path_Buffer, _value : string) -> bool {
    if len(_value) <= 0 {
        _buf.len = 0
        return true
    }

    if len(_value) > MAX_LEVEL_PATH_BYTES {
        log.errorf("PathBuffer_Set: path too long ({} bytes)", len(_value)) 
        return false
    }

    for i := 0; i < len(_value); i += 1 {
        _buf.buf[i] = _value[i]
    }
    _buf.len = len(_value)

    return true
}

PathBuffer_String :: proc(_buf : ^Path_Buffer) -> string {
    return string(_buf.buf[:_buf.len])
}

// Takes in the level state and records all the level data into the saveable .json format.
BuildTileLayerData :: proc(_level : ^Level_State, _layer_name := "ground") -> leveldata.Tile_Layer_Data {
    placements := make([dynamic]leveldata.Tile_Placement_Data, 0, len(_level.tmap.tiles))

    for cell, inst in _level.tmap.tiles {
        def, ok := GetTileDef(&_level.defsLibrary, inst.def_id)
        if !ok do continue

        append(&placements, leveldata.Tile_Placement_Data{
            x    = cell.x,
            y    = cell.y,
            tile = def.key,
        })
    }

    slice.stable_sort_by(placements[:], proc(a, b: leveldata.Tile_Placement_Data) -> bool {
        if a.y != b.y do return a.y < b.y
        return a.x < b.x
    })

    return leveldata.Tile_Layer_Data{
        name  = _layer_name,
        tiles = placements,
    }
}

ApplyTileLayerData :: proc(_level : ^Level_State, _layer : leveldata.Tile_Layer_Data) -> bool {
    ClearTilemap(&_level.tmap)

    missing_defs := 0

    for i := 0; i < len(_layer.tiles); i += 1 {
        t := _layer.tiles[i]

        def_id, ok := FindTileDefByKey(&_level.defsLibrary, t.tile)
        if !ok {
            missing_defs += 1
            log.warnf("ApplyTileLayerData: missing tile def key '{}'", t.tile)
            continue
        }

        PlaceTile(&_level.tmap, Tile_Coord{x = t.x, y = t.y}, def_id)
    }

    if missing_defs > 0 {
        log.warnf("ApplyTileLayerData: skipped {} tiles due to missing defs", missing_defs)
    }

    return true
}

SaveCurrentLevel :: proc(_level : ^Level_State) -> bool {
    if _level.editor.current_level_path.len == 0 {
        log.warn("SaveCurrentLevel: no current level path set")
        return false
    }

    file := leveldata.Level_File{
        version = 1,
        tile_layers = make([dynamic]leveldata.Tile_Layer_Data, 0, 1),
    }
    defer leveldata.DestroyLevelFile(&file)

    append(&file.tile_layers, BuildTileLayerData(_level))

    path := PathBuffer_String(&_level.editor.current_level_path)
    ok := leveldata.SaveLevelFile(path, file)
    if ok {
        log.infof("Saved tilemap level: {}", path)
    }

    return ok
}

LoadLevelFromPath :: proc(_level : ^Level_State, _path : string) -> bool {
    file, ok := leveldata.LoadLevelFile(_path)
    if !ok {
        return false
    }
    defer leveldata.DestroyLevelFile(&file)

    if len(file.tile_layers) <= 0 {
        log.errorf("LoadLevelFromPath: '{}' contains no tile layers", _path)
        return false
    }

    if !ApplyTileLayerData(_level, file.tile_layers[0]) {
        return false
    }

    if !PathBuffer_Set(&_level.editor.current_level_path, _path) {
        log.warnf("LoadLevelFromPath: loaded level, but failed to store current path '{}'", _path)
    }

    log.infof("Loaded tilemap level: {}", _path)
    return true
}
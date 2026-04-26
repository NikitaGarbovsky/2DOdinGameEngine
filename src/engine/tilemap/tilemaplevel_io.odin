#+vet explicit-allocators
package tilemap

import "../leveldata"
import "core:log"
import "core:slice"

/// Manages transforming the tilemap grid data to level data to save it.

// Just adds the path string to the path buffer object
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
BuildTileLayerData :: proc(_level : ^Level_State, _layer : Tilemap_Layer) -> leveldata.Tile_Layer_Data {
    tmap := GetTilemapForLayer(_level, _layer)
    placements := make([dynamic]leveldata.Tile_Placement_Data, 0, len(tmap.tiles),  context.allocator)

    for cell, inst in tmap.tiles {
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
        name  = TilemapLayerName(_layer),
        tiles = placements,
    }
}

ApplyTileLayerData :: proc(_level : ^Level_State, _layer : Tilemap_Layer, _layer_data : leveldata.Tile_Layer_Data) -> bool {
    tmap := GetTilemapForLayer(_level, _layer)
    ClearTilemap(tmap)

    missing_defs := 0

    for i := 0; i < len(_layer_data.tiles); i += 1 {
        t := _layer_data.tiles[i]

        def_id, ok := FindTileDefByKey(&_level.defsLibrary, t.tile)
        if !ok {
            missing_defs += 1
            log.warnf("ApplyTileLayerData: missing tile def key '{}'", t.tile)
            continue
        }

        PlaceTile(tmap, Tile_Coord{x = t.x, y = t.y}, def_id)
    }

    if missing_defs > 0 {
        log.warnf("ApplyTileLayerData: skipped {} tiles due to missing defs", missing_defs)
    }

    return true
}
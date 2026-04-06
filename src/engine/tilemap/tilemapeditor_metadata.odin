package tilemap

import "core:encoding/json"
import "core:os" 
import "core:log"
import "core:fmt"


///
/// This manages the saving & loading of tilemap metadata. (currently only the origin point of each tile type)
///


// Stores the local override configured in the saved metadata file
Tile_Origin_Override :: struct {
    key    : string,
    origin : [2]f32,
    // #TODO: store more metadata about tiles here.
}

// The object that will map to the .json file, contains the tile metadata data
Tile_Origin_Override_File :: struct {
    tiles : [dynamic]Tile_Origin_Override,
}

SaveTileOriginOverrides :: proc(_level : ^Level_State) {
    if len(_level.resources.tileset_meta_path) == 0 do return

    file := Tile_Origin_Override_File{
        tiles = make([dynamic]Tile_Origin_Override, 0, len(_level.defsLibrary.defs)),
    }
    defer delete(file.tiles)

    for i := 0; i < len(_level.defsLibrary.defs); i += 1 {
        def := _level.defsLibrary.defs[i]

        append(&file.tiles, Tile_Origin_Override{
            key    = def.key,
            origin = def.origin,
        })
    }

    data, err := json.marshal(
        file,
        json.Marshal_Options{
            pretty     = true,
            use_spaces = true,
            spaces     = 2,
        },
    )
    if err != nil {
        errstring := err.(json.Marshal_Data_Error)
        log.debugf("Error when jason marshalling: {}", errstring) // #TODO: add in engine console output here.
    }
    defer delete(data)

    write_err := os.write_entire_file(_level.resources.tileset_meta_path, data)
    if write_err != nil {
        // #TODO: add in engine console output here.
        log.debugf("Failed to write to origins file")
        return
    }
    fmt.printf("Successfully Saved Tile Origins to metadata file: {}", _level.resources.tileset_meta_path) // #TODO: add in engine console output here.
}

LoadTileOriginOverrides :: proc(_level : ^Level_State) {
    if len(_level.resources.tileset_meta_path) == 0 do return

    data, read_err := os.read_entire_file_from_path(_level.resources.tileset_meta_path, context.temp_allocator) // #TODO: CLEAR THIS, ALLOCATING MEMORY!
    if read_err != nil {
        // Missing file is fine on first run
        return
    }

    file: Tile_Origin_Override_File
    unmarshal_err := json.unmarshal(data, &file, .JSON, context.temp_allocator) // #TODO: CLEAR THIS, ALLOCATING MEMORY!
    if unmarshal_err != nil {
        // #TODO: add in engine console output here.
        return
    }

    for i := 0; i < len(file.tiles); i += 1 {
        entry := file.tiles[i]

        def_id, ok := FindTileDefByKey(&_level.defsLibrary, entry.key)
        if !ok do continue

        def, ok2 := GetTileDef(&_level.defsLibrary, def_id)
        if !ok2 do continue

        def.origin = entry.origin
    }
}
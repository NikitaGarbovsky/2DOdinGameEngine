package leveldata

import "core:encoding/json"
import "core:os"
import "core:log"

///
/// Helpers for leveldata loading, saving & destroying.
///

// Saves the collected level data to the json level file 
SaveLevelFile :: proc(
    _path : string, 
    _file : Level_File
) -> bool {
    data, error := json.marshal(
        _file,
        json.Marshal_Options{
            pretty = true,
            use_spaces = true,
            spaces = 2,
        },
    )
    if error != nil {
        log.errorf("SaveLevelFile: json marshal failed: {}", error)
        return false
    }
    defer delete(data)

    write_err := os.write_entire_file(_path,data)
    if write_err != nil {
        log.errorf("SaveLevelFile: failed to write '{}': {}", _path, write_err)
        return false
    }

    return true
}

// Loads the level data (tilemap & entities) from the json level file
LoadLevelFile :: proc(
    _path : string, 
    _allocator := context.allocator
) -> (Level_File, bool) {
    data, read_err := os.read_entire_file_from_path(_path, _allocator)
    if read_err != nil {
        log.errorf("LoadLevelFile: failed to read '{}': {}", _path, read_err)
        return Level_File{}, false
    }

    file : Level_File 
    err := json.unmarshal(data, &file, .JSON, _allocator)
    if err != nil {
        log.errorf("LoadLevelFile: json parse failed for '{}': {}", _path, err)
        return Level_File{}, false
    }

    if file.version != 1 {
        log.errorf("LoadLevelFile: unsupported level version {} in '{}'", file.version, _path)
        DestroyLevelFile(&file)
        return Level_File{}, false
    }

    return file, true
}


DestroyLevelFile :: proc(_file : ^Level_File) {
    for i := 0; i < len(_file.tile_layers); i += 1 {
        if cap(_file.tile_layers[i].tiles) > 0 {
            delete(_file.tile_layers[i].tiles)
        }
    }

    if cap(_file.tile_layers) > 0 {
        delete(_file.tile_layers)
    }

    if cap(_file.entities) > 0 {
        delete(_file.entities)
    }
}
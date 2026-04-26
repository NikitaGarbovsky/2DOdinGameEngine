#+vet explicit-allocators
package tilemap

import sdl "vendor:sdl3"
import "core:log"
import "core:sync"
import "base:runtime"
import "core:strings"

// Manages the file dialogue that occurs from loading/saving tilemap.

LEVEL_FILE_SUFFIX :: ".level.json"

Level_Dialog_Results :: struct {
    should_load : bool,
    load_path : Path_Buffer,

    should_save : bool,
    save_path : Path_Buffer,
}

level_file_filters := [1]sdl.DialogFileFilter{
    {name = "Level Files", pattern = "level.json"},
}

// Executed when a open dialog request is sent to SDL3.
TilemapOpenDialogCallback :: proc "c" (userdata : rawptr, filelist : [^]cstring, _filter : i32) {
    context = runtime.default_context()
    level := cast(^Level_State)userdata
    if level == nil do return

    if filelist == nil {
        log.errorf("Open level dialog failed: {}", sdl.GetError())
        return
    }

    first := filelist[0]
    if first == nil {
        // cancelled
        return
    }

    path := string(first)

    sync.mutex_lock(&level.editor.dialog_mutex)
    defer sync.mutex_unlock(&level.editor.dialog_mutex)

    if !PathBuffer_Set(&level.editor.pending_load_path, path) {
        log.error("Open level dialog returned a path that was too long")
        return
    }

    level.editor.has_pending_load_path = true
}

// Executed when a save dialog request is sent to SDL3.
TilemapSaveDialogCallback :: proc "c" (userdata : rawptr, filelist : [^]cstring, _filter : i32) {
    context = runtime.default_context() 
    level := cast(^Level_State)userdata
    if level == nil do return

    if filelist == nil {
        log.errorf("Save level dialog failed: {}", sdl.GetError())
        return
    }

    first := filelist[0]
    if first == nil {
        // Cancelled 
        return
    }

    raw_path := string(first)
    path := AppendLevelFileSuffix(raw_path)

    sync.mutex_lock(&level.editor.dialog_mutex)
    defer sync.mutex_unlock(&level.editor.dialog_mutex)

    if !PathBuffer_Set(&level.editor.pending_save_path, path) {
        log.error("Save level dialog return a path that was too long")
        return
    }

    level.editor.has_pending_save_path = true
}

// Used by the imgui buttons to request(async) a SDL3 open dialogue
RequestOpenLevelDialog :: proc(_level : ^Level_State) {
    sdl.ShowOpenFileDialog(
        TilemapOpenDialogCallback,
        _level,
        nil,
        &level_file_filters[0],
        len(level_file_filters),
        nil,
        false,
    )
}

// Used by the imgui buttons to request(async) a SDL3 save dialogue
RequestSaveLevelDialog :: proc(_level : ^Level_State) {
    default_location : cstring = nil

    if _level.editor.current_level_path.len > 0 {
        default_location = strings.clone_to_cstring(PathBuffer_String(&_level.editor.current_level_path), context.allocator)
    }

    sdl.ShowSaveFileDialog(
        TilemapSaveDialogCallback,
        _level,
        nil,
        &level_file_filters[0],
        len(level_file_filters),
        default_location
    )
}

// If the user hasn't saved this level, it will auto save as.
SaveCurrentLevelOrPromptSaveAs :: proc(_level : ^Level_State) -> bool {
    sync.mutex_lock(&_level.editor.dialog_mutex)
    defer sync.mutex_unlock(&_level.editor.dialog_mutex)

    // If we already know the level path, queue a save request immediately.
    if _level.editor.current_level_path.len > 0 {
        if !PathBuffer_Set(&_level.editor.pending_save_path, PathBuffer_String(&_level.editor.current_level_path)) {
            log.error("SaveCurrentLevelOrPromptSaveAs: current level path was too long")
            return false
        }

        _level.editor.has_pending_save_path = true
        return true
    }

    // Otherwise ask the user where to save it.
    RequestSaveLevelDialog(_level)
    return false
}

// When the callback executes for the dialog results, this pumps those results
// to the main thread. 
PumpPendingDialogResults :: proc(_level : ^Level_State) -> Level_Dialog_Results {
    results := Level_Dialog_Results{}

    local_load_path : Path_Buffer
    has_load_path := false

    local_save_path : Path_Buffer
    has_save_path := false

    sync.mutex_lock(&_level.editor.dialog_mutex)

    if _level.editor.has_pending_load_path {
        local_load_path = _level.editor.pending_load_path
        _level.editor.pending_load_path.len = 0
        _level.editor.has_pending_load_path = false
        has_load_path = true
    }

    if _level.editor.has_pending_save_path {
        local_save_path = _level.editor.pending_save_path
        _level.editor.pending_save_path.len = 0
        _level.editor.has_pending_save_path = false
        has_save_path = true
    }

    sync.mutex_unlock(&_level.editor.dialog_mutex)

    if has_load_path {
        results.should_load = true
        results.load_path = local_load_path
    }

    if has_save_path {
        path := PathBuffer_String(&local_save_path)

        if PathBuffer_Set(&_level.editor.current_level_path, path) {
            results.should_save = true
            results.save_path = local_load_path
        } else {
            log.errorf("PumpPendingDialogResults: failed to store save path '{}'", path)
        }
    }

    return results
}

// ========= Helpers =========
HasLevelFileSuffix :: proc(_path : string) -> bool {
    return strings.has_suffix(_path, LEVEL_FILE_SUFFIX)
}

AppendLevelFileSuffix :: proc(_path : string) -> string {
    if HasLevelFileSuffix(_path) {
        return _path
    }

    if strings.has_suffix(_path, ".json") {
        base := _path[:len(_path)-len(".json")]
        s := []string {base, ".level.json"}
        return strings.concatenate(s,  context.allocator)
    }

    s := []string {_path, ".level.json"}
    return strings.concatenate(s,  context.allocator)
}

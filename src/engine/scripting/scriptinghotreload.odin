package scripting 

import lua "vendor:lua/5.4"
import "core:time"
import "core:os"
import "core:strings"
import "core:fmt"
import "../ecs"
import "../components"

///
/// This manages the ability for lua scripts that are bound to entities to be hot-reloaded.
/// The scripts last modification time is recorded, then it's checked each update if thats changed,
/// if it is, it's reloaded.
///

// Gets the last time the lua script file was modified.
@private
GetFileWriteTime :: proc(_path : string) -> (time.Time, bool) {
    info, err := os.stat(_path, context.allocator)
    if err != os.ERROR_NONE do return {}, false
    return info.modification_time, true
}

// Returns true if the script file has changed on disk, and updates the cached write time.
@private
ShouldReloadScript :: proc(_instance : ^Script_Instance) -> bool {
    write_time, ok := GetFileWriteTime(_instance.path)
    if !ok do return false

    if time.diff(_instance.last_write_time, write_time) > 0 {
        _instance.last_write_time = write_time
        return true
    }

    return false
}

// Loads the lua scripts table data structure for use for gameplay scripting.
@private 
LoadScriptTable :: proc(_runtime : ^Script_Runtime, _path : string) -> (i32, bool) {
    status := lua.L_dofile(_runtime.L, strings.clone_to_cstring(_path))

    // Error detected
    if status != 0 { 
        fmt.printf("Lua load error (%s): %s\n", _path, lua.tostring(_runtime.L, -1))
        lua.pop(_runtime.L, 1)
        return SCRIPT_TABLE_REGISTRY_NIL, false
    }

    // Validation
    if !lua.istable(_runtime.L, -1) {
        fmt.printf("Lua script must return a table: %s\n", _path)
        lua.pop(_runtime.L, 1)
        return SCRIPT_TABLE_REGISTRY_NIL, false
    }

    table_ref := lua.L_ref(_runtime.L, lua.REGISTRYINDEX)
    return table_ref, true
}

@private 
EnsureScriptLoaded :: proc(
    _runtime : ^Script_Runtime,
    _entity : ecs.Entity,
    _script : ^components.Script,
) -> bool {
    instance, exists := _runtime.instances[_entity]

    // If the script hasn't been loaded, 
    if !exists {
        // Load it.
        table_ref, ok := LoadScriptTable(_runtime, _script.path)
        if !ok do return false

        // Stores now as the latest write time. (for hot-reload)
        write_time, _ := GetFileWriteTime(_script.path)

        // Create this as new script instance,
        _runtime.instances[_entity] = Script_Instance {
            table_ref = table_ref,
            started = false,
            last_write_time = write_time,
            path = _script.path,
        }
        return true
    }

    // Reload the script if a change has been detected.
    if _script.hot_reload && ShouldReloadScript(&instance) {
        if instance.table_ref != SCRIPT_TABLE_REGISTRY_NIL {
            lua.L_unref(_runtime.L, lua.REGISTRYINDEX, instance.table_ref)
        }

        table_ref, ok := LoadScriptTable(_runtime, _script.path)
        if !ok {
            instance.table_ref = SCRIPT_TABLE_REGISTRY_NIL
            instance.started = false 
            _runtime.instances[_entity] = instance  
            return false
        }

        instance.table_ref = table_ref
        instance.started = false
        instance.path = _script.path
        _runtime.instances[_entity] = instance 

        fmt.printf("Lua hot-reloaded: %s\n", _script.path)
        return true
    }

    return true
}

// Script API for lua script "Start". Only runs once, on the next frame after the entity is created.
@private 
CallScriptStart :: proc(
    _runtime : ^Script_Runtime,
    _entity : ecs.Entity,
) {
    instance := _runtime.instances[_entity]
    if instance.table_ref == SCRIPT_TABLE_REGISTRY_NIL do return
    if instance.started do return

    lua.rawgeti(_runtime.L, lua.REGISTRYINDEX, lua.Integer(instance.table_ref))
    lua.getfield(_runtime.L, -1, "Start")

    if lua.isfunction(_runtime.L, -1) {
        lua.pushinteger(_runtime.L, lua.Integer(_entity.id))
        if lua.pcall(_runtime.L, 1, 0, 0) != 0{
            fmt.printf("Lua start() error for entity %v: %s\n", _entity, lua.tostring(_runtime.L, -1))
            lua.pop(_runtime.L, 1)
        }
    } else {
        lua.pop(_runtime.L, 1)
    }

    lua.pop(_runtime.L, 1)

    instance.started = true
    _runtime.instances[_entity] = instance
}

// Script API for lua script "Update". Runs every update loop.
@private 
CallScriptUpdate :: proc(
    _runtime : ^Script_Runtime,
    _entity : ecs.Entity,
    _dt : f32,
) {
    instance := _runtime.instances[_entity]
    if instance.table_ref == SCRIPT_TABLE_REGISTRY_NIL do return 

    lua.rawgeti(_runtime.L, lua.REGISTRYINDEX, lua.Integer(instance.table_ref))
    lua.getfield(_runtime.L, -1, "Update")

    if lua.isfunction(_runtime.L, -1) {
        lua.pushinteger(_runtime.L, lua.Integer(_entity.id))
        lua.pushnumber(_runtime.L, lua.Number(_dt))

        if lua.pcall(_runtime.L, 2, 0, 0) != 0 {
            fmt.printf("Lua update() error for entity %v: %s\n", _entity, lua.tostring(_runtime.L, -1))
            lua.pop(_runtime.L, 1)
        }
    } else {
        lua.pop(_runtime.L, 1)
    }

    lua.pop(_runtime.L, 1)
}

// Runs on the lua api OnDestroy when the entity is destroyed engine side.
@private 
CallScriptOnDestroy :: proc(
    _runtime : ^Script_Runtime,
    _entity : ecs.Entity,
) {
    instance, ok := _runtime.instances[_entity]
    if !ok do return
    if instance.table_ref == SCRIPT_TABLE_REGISTRY_NIL do return

    lua.rawgeti(_runtime.L, lua.REGISTRYINDEX, lua.Integer(instance.table_ref))
    lua.getfield(_runtime.L, -1, "OnDestroy")

    if lua.isfunction(_runtime.L, -1) {
        lua.pushinteger(_runtime.L, lua.Integer(_entity.id))

        if lua.pcall(_runtime.L, 1, 0, 0) != 0 {
            fmt.printf("Lua OnDestroy() error for entity %v: %s\n", _entity, lua.tostring(_runtime.L, -1))
            lua.pop(_runtime.L, 1)
        }
    } else {
        lua.pop(_runtime.L, 1)
    }

    lua.pop(_runtime.L, 1)
}


package scripting 

import "../ecs"
import lua "vendor:lua/5.4"
import "core:fmt"

///
/// Contains api binding callbacks for gameplay scripting purposes.
/// Pretty much identical to Unitys.
///
/// Contains: 
/// --- OnStart
/// --- OnUpdate
/// --- OnDestroy
/// --- OnInteract
///


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
    lua.getfield(_runtime.L, -1, "OnStart")

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
    lua.getfield(_runtime.L, -1, "OnUpdate")

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

// Runs the lua api OnInteract when an entity is interacted with.
@private 
CallScriptOnInteract :: proc(
    _runtime : ^Script_Runtime,
    _entity : ecs.Entity,
    _interactor : ecs.Entity,
) {
    instance, ok := _runtime.instances[_entity]
    if !ok do return 
    if instance.table_ref == SCRIPT_TABLE_REGISTRY_NIL do return

    lua.rawgeti(_runtime.L, lua.REGISTRYINDEX, lua.Integer(instance.table_ref))
    lua.getfield(_runtime.L, -1, "OnInteract")

    if lua.isfunction(_runtime.L, -1) {
        lua.pushinteger(_runtime.L, lua.Integer(_entity.id))
        lua.pushinteger(_runtime.L, lua.Integer(_interactor.id))

        if lua.pcall(_runtime.L, 2, 0, 0) != 0 {
            fmt.printf(
                "Lua OnInteract() error for entity %v: %s\n",
                _entity,
                lua.tostring(_runtime.L, -1),
            )
            lua.pop(_runtime.L, 1)
        }
    } else {
        lua.pop(_runtime.L, 1)
    }

    lua.pop(_runtime.L, 1)
}
package scripting

import lua "vendor:lua/5.4"

import "../ecs"
import "../physics"
import "../input"
import "../components"

///
/// Main scripting file containing the main functionality for running the lua scripting runtime.
///


// Starts the lua scripting runtime, initializes resources for holding 
// all entity script references.
InitializeScripting :: proc(_runtime : ^Script_Runtime) {
    _runtime.L = lua.L_newstate()
    lua.L_openlibs(_runtime.L)
    _runtime.instances = make(map[ecs.Entity]Script_Instance)

    RegisterScriptBindings(_runtime)
}

// Ensures script instances are loaded, then runs lua API Start once, and Update every frame for scripted entities.
UpdateLuaScripts :: proc(
    _runtime : ^Script_Runtime,
    _world : ^ecs.EntityWorld,
    _physics_world : ^physics.PhysicsWorld,
    _input_state : ^input.InputState,
    _dt : f32,
) {
    if _runtime.L == nil do return 

    // Update the scripting bridge with the current engine state for this frame.
    _runtime.bridge_context.world = _world
    _runtime.bridge_context.physics_world = _physics_world
    _runtime.bridge_context.input_state = _input_state

    // Assign a pointer to runtime, so lua api can reference it,
    current_runtime = _runtime
    defer current_runtime = nil

    // Loop through all entitys that have script components attached
    // and call their lua script Start & Update functions 
    for i := 0; i < len(_world.scripts.entities); i += 1 {
        entity := _world.scripts.entities[i]
        script := &_world.scripts.data[i]

        if !script.enabled do continue 

        if !EnsureScriptLoaded(_runtime, entity, script) do continue 

        CallScriptStart(_runtime, entity)
        CallScriptUpdate(_runtime, entity, _dt)
    }
}

// Clean up lua scripting state
ShutdownScripting :: proc(_runtime : ^Script_Runtime) {
    if _runtime.L != nil {
        for entity, instance in _runtime.instances {
            if instance.table_ref != SCRIPT_TABLE_REGISTRY_NIL {
                lua.L_unref(_runtime.L, lua.REGISTRYINDEX, instance.table_ref)
            }
            delete_key(&_runtime.instances, entity)
        }

        lua.close(_runtime.L)
        _runtime.L = nil
    }
}

// Remove's a script instance that is bound to an entity.
RemoveScriptInstance :: proc(
    _runtime : ^Script_Runtime,
    _entity : ecs.Entity,
) {
    instance, ok := _runtime.instances[_entity]
    if !ok do return 

    if instance.table_ref != SCRIPT_TABLE_REGISTRY_NIL {
        lua.L_unref(_runtime.L, lua.REGISTRYINDEX, instance.table_ref)
    }

    delete_key(&_runtime.instances, _entity)
}

// Notifies the scripting logic to execute OnDestory for an associated entity.
// #TODO: Route all entity destruction through a central destroy pipeline so OnDestroy always runs.
// If death effects need multiple frames(animation), probs should mrak the entity as pending-destroy instead of deleting immediately.
NotifyEntityDestroyed :: proc(
    _runtime : ^Script_Runtime,
    _entity : ecs.Entity,
) {
    if _runtime.L == nil do return 

    current_runtime = _runtime
    defer current_runtime = nil

    CallScriptOnDestroy(_runtime, _entity)
    RemoveScriptInstance(_runtime, _entity)
}

#+vet explicit-allocators
package scripting

import "core:time"
import "../ecs"
import "../physics"
import lua "vendor:lua/5.4"
import "../input"

///
/// Contains all the type definition for use within the scripting system.
///

current_runtime : ^Script_Runtime

// The scripting lua runtime that is run by the application. Stores references
// to every lua script loaded and engine state for reference by lua api.
Script_Runtime :: struct {
    L : ^lua.State,
    instances : map[ecs.Entity]Script_Instance,
    bridge_context : Script_Bridge_Context
}

// An instance of a script that is bound to an entities script component.
Script_Instance :: struct {
    table_ref : i32,
    started : bool,
    last_write_time : time.Time,
    path : string,
}

// Stores references to the engine state. This is so raw engine state isn't passed
// around throughout scripting logic. Updated everyframe.
Script_Bridge_Context :: struct {
    world : ^ecs.EntityWorld,
    physics_world : ^physics.PhysicsWorld,
    input_state : ^input.InputState,
}

// Compile time constant value representing an invalid Lua registry table reference.
SCRIPT_TABLE_REGISTRY_NIL : i32 : -1
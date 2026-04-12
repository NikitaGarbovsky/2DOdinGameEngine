package scripting 

import "base:runtime"
import "core:math/linalg"
import lua "vendor:lua/5.4"
import "core:fmt"
import "../ecs"
import "../physics"
import "../animation"

///
/// This manages the exposed bindings from engine-odin owned logic to lua
/// scripting that can be called. Add to ScriptAPI/engine_api.lua for lsp 
/// integration.
///

// Registers all the lua api functions that can be utilized from lua scripts
RegisterScriptBindings :: proc(_runtime : ^Script_Runtime) {
    lua.pushcfunction(_runtime.L, Lua_SetVelocity)
    lua.setglobal(_runtime.L, "SetVelocity")

    lua.pushcfunction(_runtime.L, Lua_GetInputMoveX)
    lua.setglobal(_runtime.L, "GetInputMoveX")

    lua.pushcfunction(_runtime.L, Lua_GetInputMoveY)
    lua.setglobal(_runtime.L, "GetInputMoveY")

    lua.pushcfunction(_runtime.L, Lua_SetAnimationClip)
    lua.setglobal(_runtime.L, "SetAnimationClip")

    lua.pushcfunction(_runtime.L, Lua_SetAnimationDirection)
    lua.setglobal(_runtime.L, "SetAnimationDirection")

    lua.pushcfunction(_runtime.L, Lua_DestroyEntity)
    lua.setglobal(_runtime.L, "DestroyEntity")

    lua.pushcfunction(_runtime.L, Lua_GetGold)
    lua.setglobal(_runtime.L, "GetGold")

    lua.pushcfunction(_runtime.L, Lua_AddGold)
    lua.setglobal(_runtime.L, "AddGold")

    lua.pushcfunction(_runtime.L, Lua_TryRemoveGold)
    lua.setglobal(_runtime.L, "TryRemoveGold")
}


// ======================== Lua helpers for conversion of types ========================

@private 
LuaCheckEntity :: proc(_L : ^lua.State, _idx : int) -> ecs.Entity {
    raw := lua.tointeger(_L, i32(_idx))
    return ecs.Entity{id = u32(raw)}
}

@private 
LuaCheckF32 :: proc(_L : ^lua.State, _idx : int) -> f32 {
    return f32(lua.tonumber(_L, i32(_idx)))
}

LuaCheckString :: proc(_L : ^lua.State, _idx : int) -> string {
    return string(lua.tostring(_L, i32(_idx)))
}

// ======================== Lua-callable engine bindings ========================

@private
Lua_SetVelocity :: proc "c" (_L : ^lua.State) -> i32 {
    context = runtime.default_context()
    entity := LuaCheckEntity(_L, 1)
    x := LuaCheckF32(_L, 2)
    y := LuaCheckF32(_L, 3)

    vel : linalg.Vector2f32 = {x, y}
    physics.SetLinearVelocity(current_runtime.bridge_context.physics_world, entity, vel)

    return 0
}

@private
Lua_SetAnimationClip :: proc "c" (_L : ^lua.State) -> i32 {
    context = runtime.default_context()
    entity := LuaCheckEntity(_L, 1)
    state := LuaCheckString(_L, 2)

    animator, ok := ecs.GetComponent(&current_runtime.bridge_context.world.animators, entity)
    if ok {
        animator.requested_state = state
    }

    return 0
}

@private
Lua_GetInputMoveX :: proc "c" (_L : ^lua.State) -> i32 {
    move_x : f32 = 0

    if current_runtime.bridge_context.input_state.move_left do move_x -= 1
    if current_runtime.bridge_context.input_state.move_right do move_x += 1

    lua.pushnumber(_L, lua.Number(move_x))
    return 1
}

@private
Lua_GetInputMoveY :: proc "c" (_L : ^lua.State) -> i32 {
    move_y : f32 = 0

    if current_runtime.bridge_context.input_state.move_up do move_y -= 1
    if current_runtime.bridge_context.input_state.move_down do move_y += 1

    lua.pushnumber(_L, lua.Number(move_y))
    return 1
}

@private
Lua_SetAnimationDirection :: proc "c" (_L : ^lua.State) -> i32 {
    context = runtime.default_context()
    entity := LuaCheckEntity(_L, 1)
    x := LuaCheckF32(_L, 2)
    y := LuaCheckF32(_L, 3)

    animator, ok := ecs.GetComponent(&current_runtime.bridge_context.world.animators, entity)
    if !ok do return 0

    dir : linalg.Vector2f32 = {x, y}
    animation.SetAnimationDirectionFromMovementVelocity(dir, &animator.anim_player)

    return 0
}

@private 
Lua_DestroyEntity :: proc "c" (_L : ^lua.State) -> i32 {
    context = runtime.default_context()
    entity := LuaCheckEntity(_L, 1)

    runtime := current_runtime

    NotifyEntityDestroyed(runtime, entity)
    ecs.DeleteEntity(runtime.bridge_context.world, entity)

    return 0
}

@private
Lua_GetGold :: proc "c" (_L : ^lua.State) -> i32 {
    context = runtime.default_context()
    entity := LuaCheckEntity(_L, 1)

    amount : i32 = 0
    inventory, ok := ecs.GetComponent(&current_runtime.bridge_context.world.inventory, entity)
    if ok {
        
        amount = inventory.gold
        
    }

    lua.pushinteger(_L, lua.Integer(amount))
    return 1
}

@private 
Lua_AddGold :: proc "c" (_L : ^lua.State) -> i32 {
    context = runtime.default_context()
    entity := LuaCheckEntity(_L, 1)
    amount := i32(lua.tointeger(_L, 2))

    added : i32 = 0
    inventory, ok := ecs.GetComponent(&current_runtime.bridge_context.world.inventory, entity)

    if ok && amount > 0 {
        if inventory.capacity <= 0 {
            inventory.gold += amount 
            added = amount 
        } else {
            free_space := inventory.capacity - inventory.gold
            if free_space < 0 do free_space = 0

            added = amount 
            if added > free_space do added = free_space

            inventory.gold += added
        }
    }

    lua.pushinteger(_L, lua.Integer(added))
    return 1    
}

@private 
Lua_TryRemoveGold :: proc "c" (_L : ^lua.State) -> i32 {
    context = runtime.default_context()
    entity := LuaCheckEntity(_L, 1)
    amount := i32(lua.tointeger(_L, 2))

    success : b32 = false
    container, ok := ecs.GetComponent(&current_runtime.bridge_context.world.inventory, entity)

    if ok && amount > 0 && container.gold >= amount {
        container.gold -= amount
        success = true
    }

    lua.pushboolean(_L, success)
    return 1
}
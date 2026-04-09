package systems

import "core:time"
import "../input"
import "../ecs"
import "../renderer"
import linalg "core:math/linalg"
import "../physics"
import "../animation"
import "core:fmt"
import lua "vendor:lua/5.4"
import "core:os"
import "core:strings"

/// A system is a smaller alotment of functionality that is run by main application within it's main loop.

///
/// Manages the playmode updates when playing the game.
///

// #TODO: Comment this.

Play_Mode_Context :: struct {
    input_state : ^input.InputState,
    frame_stats : ^Frame_Stats,
    entity_world : ^ecs.EntityWorld,
    renderer : ^renderer.Renderer,
    player_entity : ecs.Entity,
    has_player : bool,
    move_speed : f32,
    physics_world : ^physics.PhysicsWorld,
    animation_player : ^animation.Animation_Player,
}

L : ^lua.State
speed : f32
last_write_time : time.Time
script_path : cstring = "Resources/scripts/movement.lua"

InitializePlayMode :: proc() {
    L = lua.L_newstate()
    lua.L_openlibs(L)
    
    info, _ := os.stat(string(script_path), context.allocator)
    last_write_time = info.modification_time

    status : = lua.L_dofile(L, script_path)
    if status != 0 {
        fmt.printf("Error loading file: %s\n", lua.tostring(L, -1))
    }

    lua.getglobal(L, "returnMovementSpeed")

    if lua.pcall(L,0,1,0) != 0{

    }
    speed = f32(lua.tonumber(L, -1))

    lua.pop(L, 1)
}
// Updates the player position based off input 
UpdatePlayMode :: proc(_context : ^Play_Mode_Context) {
    transform, ok := ecs.GetComponent(&_context.entity_world.transforms, _context.player_entity)
    if !ok do return

    if ShouldReloadScript(strings.clone_from_cstring(script_path)) {
        if lua.L_dofile(L, script_path) == 0 {
            fmt.println("Lua script hot-reloaded successfully!")
            lua.getglobal(L, "returnMovementSpeed")

            if lua.pcall(L,0,1,0) != 0{

            }
            speed = f32(lua.tonumber(L, -1))

            lua.pop(L, 1)
        }
    }
    move_dir : linalg.Vector2f32 = {0, 0}

    // Add velocity based off input
    if _context.input_state.move_left do move_dir.x -= 1
    if _context.input_state.move_right do move_dir.x += 1
    if _context.input_state.move_up do move_dir.y -= 1
    if _context.input_state.move_down do move_dir.y += 1

    if move_dir.x != 0 || move_dir.y != 0 {
        move_dir = linalg.normalize(move_dir)
    }

    _context.move_speed = speed
    vel := move_dir * _context.move_speed
    physics.SetLinearVelocity(_context.physics_world, _context.player_entity, vel)

    // TODO: this is all very in-efficient and should be ripped out and put somewhere else
    // Set the current clip based off movement direction.
    animation.SetAnimationDirectionFromMovementVelocity(move_dir, _context.animation_player)
    if move_dir == {0,0} { // No movement, set idle
        idle_clip := animation.SetAnimationClipBasedOfCurrentDirection(_context.animation_player.current_direction, "idle")
        _context.animation_player.current_clip = idle_clip
    }
    else {
        walk_clip := animation.SetAnimationClipBasedOfCurrentDirection(_context.animation_player.current_direction, "walk")
        _context.animation_player.current_clip = walk_clip
    }
    
    _context.animation_player.current_clip.looping = true

    // Animation
    sprite, ok0 := ecs.GetComponent(&_context.entity_world.sprites, _context.player_entity)

    _context.animation_player.frame_timer += _context.frame_stats.deleta_seconds

    if _context.animation_player.frame_timer >= _context.animation_player.per_frame_time {
        _context.animation_player.frame_timer = 0
        _context.animation_player.current_frame += 1

        if _context.animation_player.current_frame >= len(_context.animation_player.current_clip.frames) {
            if _context.animation_player.current_clip.looping {
                _context.animation_player.current_frame = 0
            } else {
                _context.animation_player.current_frame = len(_context.animation_player.current_clip.frames) - 1
                _context.animation_player.playing = false
                
            }
        }

        frame := _context.animation_player.current_clip.frames[_context.animation_player.current_frame]
        sprite.texture = _context.animation_player.current_clip.texture
        sprite.size = frame.size / 2
        sprite.uv_min = frame.uv_min
        sprite.uv_max = frame.uv_max
        sprite.origin = frame.origin
    }

}

ShutdownPlayMode :: proc() {
    if L != nil {
        lua.close(L)
    }
}

ShouldReloadScript :: proc(_filename : string) -> bool {
    info, err := os.stat(_filename, context.allocator)
    if err != os.ERROR_NONE do return false

    if time.diff(last_write_time, info.modification_time) > 0 {
        last_write_time = info.modification_time
        return true
    }

    return false
}
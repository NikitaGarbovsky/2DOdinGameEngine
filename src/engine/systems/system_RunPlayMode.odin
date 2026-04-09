package systems

import "../input"
import "../ecs"
import "../renderer"
import linalg "core:math/linalg"
import "../physics"
import "../animation"
import "core:fmt"

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

// Updates the player position based off input 
UpdatePlayMode :: proc(_context : Play_Mode_Context) {
    transform, ok := ecs.GetComponent(&_context.entity_world.transforms, _context.player_entity)
    if !ok do return

    move_dir : linalg.Vector2f32 = {0, 0}

    // Add velocity based off input
    if _context.input_state.move_left do move_dir.x -= 1
    if _context.input_state.move_right do move_dir.x += 1
    if _context.input_state.move_up do move_dir.y -= 1
    if _context.input_state.move_down do move_dir.y += 1

    if move_dir.x != 0 || move_dir.y != 0 {
        move_dir = linalg.normalize(move_dir)
    }

    vel := move_dir * _context.move_speed
    physics.SetLinearVelocity(_context.physics_world, _context.player_entity, vel)

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
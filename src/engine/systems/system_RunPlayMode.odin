package systems

import "../input"
import "../ecs"
import "../renderer"
import linalg "core:math/linalg"
import "../physics"

/// A system is a smaller alotment of functionality that is run by main application within it's main loop.

///
/// Manages the playmode updates when playing the game.
///



Play_Mode_Context :: struct {
    input_state : ^input.InputState,
    frame_stats : ^Frame_Stats,
    entity_world : ^ecs.EntityWorld,
    renderer : ^renderer.Renderer,
    player_entity : ecs.Entity,
    has_player : bool,
    move_speed : f32,
    physics_world : ^physics.PhysicsWorld,
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
}
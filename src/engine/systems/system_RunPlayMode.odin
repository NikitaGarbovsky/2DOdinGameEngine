package systems

import "../input"
import "../ecs"
import "../renderer"
import "../tilemap"
import math "core:math"

Play_Mode_Context :: struct {
    input_state : ^input.InputState,
    frame_stats : ^Frame_Stats,
    entity_world : ^ecs.EntityWorld,
    renderer : ^renderer.Renderer,
    player_entity : ecs.Entity,
    has_player : bool,
    move_speed : f32,
}

// Updates the player position based off input #TODO: this is screenspace movement, which is not that great. 
RenderPlayMode :: proc(_context : Play_Mode_Context) {
    transform, ok := ecs.GetComponent(&_context.entity_world.transforms, _context.player_entity)
    if !ok do return

    move := [2]f32{0, 0}

    if _context.input_state.move_up do move[1] -= 1
    if _context.input_state.move_down do move[1] += 1
    if _context.input_state.move_left do move[0] -= 1
    if _context.input_state.move_right do move[0] += 1

    if move[0] != 0 || move[1] != 0 {
        len_sq := move[0] * move[0] + move[1] * move[1]
        if len_sq > 0 {
            inv_len := 1.0 / math.sqrt(len_sq)
            move[0] *= inv_len
            move[1] *= inv_len
        }

        transform.pos.x += move[0] * _context.move_speed * _context.frame_stats.deleta_seconds
        transform.pos.y += move[1] * _context.move_speed * _context.frame_stats.deleta_seconds
    }

    _context.renderer.camera.position = transform.pos
}
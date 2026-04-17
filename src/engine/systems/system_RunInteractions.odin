package systems

import "../scripting"
import "../ecs"
import "../input"
import "../renderdata"
import "../components"
import "../physics"

/// A system is a smaller alotment of functionality that is run by main application within it's main loop.

///
/// This system manages the interaction system for interacting with entities in the game, it utilizes
/// the Interactable component attached to entities.
///

// State that is passed from the main loop to trigger iterations
Interaction_State :: struct {
    hovered_entity : ecs.Entity,
    has_hovered : bool,
    hovered_text : string,
    hovered_world_pos : [2]f32,
    can_interact : bool,
}

// Finds any interactions that occur between the player and entities with an 
// interact component attached. Rn it's just mouse click interaction.
UpdateInteractionSystem :: proc(
    _runtime : ^scripting.Script_Runtime, 
    _world : ^ecs.EntityWorld, 
    _input : ^input.InputState, 
    _camera : ^renderdata.Camera2D, 
    _player_entity : ecs.Entity,
    _state : ^Interaction_State,
) {
    _state.has_hovered = false
    _state.can_interact = false
    _state.hovered_text = ""

    // 1. Convert mouse screen pos to world pos
    world_pos := renderdata.ScreenToWorldPos(_camera, {_input.mouse_x, _input.mouse_y})

    player_transform, hasPlayerTranform := ecs.GetComponent(&_world.transforms, _player_entity)

    found_interactable_entity := ecs.Entity{}
    best_dist_sq := f32(0)
    has_best := false

    // 2. Loop through all entities with interactable component
    for e, i in _world.interactables.entities {
        // 3. Require transform & collider
        transform, hasTransform := ecs.GetComponent(&_world.transforms, e)
        collider, hasCollider := ecs.GetComponent(&_world.colliders, e)
        if !hasTransform || !hasCollider do continue

        // 4. Use Collider for hover hit-testing
        is_hovered := physics.PointInsideCollider(
            {world_pos.x, world_pos.y},
            transform,
            collider,
        )
        if !is_hovered do continue

        dist_sq := DistSq(
            {world_pos.x, world_pos.y},
            {transform.pos.x, transform.pos.y},
        )

        if !has_best || dist_sq < best_dist_sq {
            has_best = true
            best_dist_sq = dist_sq
            found_interactable_entity = e
        }

    }
    if !has_best do return

    // 5. Pick the best hover 
    _state.has_hovered = true
    _state.hovered_entity = found_interactable_entity
    
    //fmt.println("Hovering entity:", found_entity.id)

    hovered_interactable, hasInteractable := ecs.GetComponent(&_world.interactables, found_interactable_entity)
    hovered_transform, hasHoveredTransform := ecs.GetComponent(&_world.transforms, found_interactable_entity)
    if !hasInteractable || !hasHoveredTransform do return
    if !hovered_interactable.enabled do return

    // 6. Check distance from player to interactable
    player_dist_sq := DistSq(
        {player_transform.pos.x, player_transform.pos.y},
        {hovered_transform.pos.x, hovered_transform.pos.y},
    )

    radius := hovered_interactable.interaction_radius
    _state.can_interact = player_dist_sq <= radius * radius

    // 7. Store popup text + popup screen position
    _state.hovered_text = hovered_interactable.prompt_text
    _state.hovered_world_pos = {
        hovered_transform.pos.x,
        hovered_transform.pos.y - hovered_interactable.popup_offset_y,
    }

    // 8. On left_pressed and in range, call Lua OnInteract(entity, player)
    if _state.can_interact && _input.left_pressed {
        scripting.NotifyEntityInteracted(_runtime, found_interactable_entity, _player_entity)
    }

}

// ============= #TODO: Probably move these to a central helper location =============

DistSq :: proc(_a, _b : [2]f32) -> f32 {
    dx := _a.x - _b.x
    dy := _a.y - _b.y

    return dx * dx + dy * dy
}
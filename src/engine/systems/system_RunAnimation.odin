#+vet explicit-allocators
package systems

import "../animation"
import "../ecs"
import "../physics"
import linalg "core:math/linalg"

///
/// Manages updating of entity animators. Runs animations per update tick.
///
/// The only reason this is here instead of in the internal engine animation package, 
/// is because animation direction for movement is reasoned based off velocity vector direction,
/// which relies on the physics package. This would cause an engine cyclical dependency, 
/// hence it is now here. #TODO: probably going to change how this system works in the future.


// Updates all animations for all entities with animator components. 
// 1. Swaps clip when requested state or facing direction changes,
// 2. Then steps/advances the current clip & updates the sprite frame data
UpdateAnimators :: proc(_world : ^ecs.EntityWorld, _dt : f32) {
    for i := 0; i < len(_world.animators.entities); i += 1 {
        e := _world.animators.entities[i]
        animator := &_world.animators.data[i]

        sprite, ok := ecs.GetComponent(&_world.sprites, e)
        if !ok do continue

        state_changed := animator.requested_state != animator.current_state
        direction_changed := animator.anim_player.current_direction != animator.applied_direction

        // Animation state changed, we need to update clip
        if state_changed || direction_changed {
            clip, found := animation.GetDirectionalClip(
                animator.bank,
                animator.requested_state,
                animator.anim_player.current_direction,
            )
            if found {
                // Play the newly found animation clip,
                animation.PlayClip(&animator.anim_player, clip, true)
                animator.current_state = animator.requested_state
                animator.applied_direction = animator.anim_player.current_direction

                // apply first frame immediately, update frame data.
                frame := animator.anim_player.current_clip.frames[animator.anim_player.current_frame]
                sprite.texture = animator.anim_player.current_clip.texture
                sprite.size = frame.size / 2
                sprite.uv_min = frame.uv_min
                sprite.uv_max = frame.uv_max
                sprite.origin = frame.origin
            }
        }

        // Advance animation. #TODO: There is no custimization of frame timing here. 
        advanced, frame := animation.StepAnimationPlayer(&animator.anim_player, _dt)
        if advanced {
            sprite.texture = animator.anim_player.current_clip.texture
            sprite.size = frame.size / 2
            sprite.uv_min = frame.uv_min
            sprite.uv_max = frame.uv_max
            sprite.origin = frame.origin
        }
    }
}

// Velocity driven generic controller that updates animation direction & clip, loops through all entities with animator components, 
// and updates the direction and animation set. #TODO: this is not currently used as there are no
// other entities in the game that have animations other than the player. This should be re-hooked up when
// that is no longer the case! 
UpdateMovementAnimationControllers :: proc(_world : ^ecs.EntityWorld, _physics : ^physics.PhysicsWorld) {
    for i := 0; i < len(_world.animators.entities); i += 1 {
        e := _world.animators.entities[i]
        animator := &_world.animators.data[i]

        if !ecs.HasComponent(&_world.sprites, e) do continue

        vel := physics.GetLinearVelocity(_physics, e)
        move_dir := vel

        if move_dir.x != 0 || move_dir.y != 0 {
            move_dir = linalg.normalize(move_dir)
            animation.SetAnimationDirectionFromMovementVelocity(move_dir, &animator.anim_player)
            animator.requested_state = "PlayerWalk"
        } else {
            animator.requested_state = "PlayerIdle"
        }
    }
}
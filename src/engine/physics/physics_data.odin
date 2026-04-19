#+vet explicit-allocators
package physics

import "../ecs"
import b2 "vendor:box2d"

// Object containing the data that represents the physics world
PhysicsWorld :: struct {
    initialized : bool, // For verification

    // The box2D world handle, (simulation space)
    world_id : b2.WorldId,

    // Physics simulation per-frame variables
    frametime_accumulator : f32,
    fixed_dt : f32,
    substeps : i32,

    // Maps Entities to box2D bodies (ID's)
    body_by_entity : map[ecs.Entity]b2.BodyId,

    // One static body holding all tile wall shapes
    tilemap_wall_body : b2.BodyId
}
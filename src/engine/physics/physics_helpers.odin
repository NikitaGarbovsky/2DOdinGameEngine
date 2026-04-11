package physics

import b2 "vendor:box2d"
import math "core:math/linalg"
import "../components"
import "../ecs"

/// Physics helpers for the physics package, mainly type converters atm.

// Helper to find rigid body type
@private 
ToB2BodyType :: proc(_kind : components.Rigid_Body_Type) -> b2.BodyType {
    switch _kind {
        case .Static : return .staticBody
        case .Kinematic : return .kinematicBody
        case .Dynamic : return .dynamicBody
    }
    return .staticBody
}
// Helper to convert 
@private 
ToB2Vec2 :: proc(_vector : math.Vector2f32) -> [2]f32 {
    return {_vector[0], _vector[1]}
}

// Returns the current linear velocity of the entity
GetLinearVelocity :: proc(
    _world : ^PhysicsWorld,
    _entity : ecs.Entity,
) -> math.Vector2f32 {
    body_id, ok := _world.body_by_entity[_entity]
    if !ok do return {0, 0}

    v := b2.Body_GetLinearVelocity(body_id)
    return {v.x, v.y}
}
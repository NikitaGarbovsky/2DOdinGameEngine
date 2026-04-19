#+vet explicit-allocators
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

// Checks if a passed in point (world space pos) is within a collider.
// Primarily used within the interaction system.
PointInsideCollider :: proc(
    _point : [2]f32,
    _transform : ^components.Transform,
    _collider : ^components.Collider,
) -> bool {
    switch _collider.shape {
    case .Box:
        min_x := _transform.pos.x - _collider.half_extends.x
        max_x := _transform.pos.x + _collider.half_extends.x
        min_y := _transform.pos.y - _collider.half_extends.y
        max_y := _transform.pos.y + _collider.half_extends.y

        return _point.x >= min_x && _point.x <= max_x &&
               _point.y >= min_y && _point.y <= max_y

    case .Circle: // There are no circle colliders yet mr garbovsky, this shouldn't run
        dx := _point.x - _transform.pos.x
        dy := _point.y - _transform.pos.y
        return dx*dx + dy*dy <= _collider.radius * _collider.radius
    }

    return false
}
package physics

import b2 "vendor:box2d"
import math "core:math/linalg"
import "../components"

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

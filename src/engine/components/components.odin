#+vet explicit-allocators
package components

import math "core:math/linalg"
import renderdata "../renderdata"
import "../animation"

///
/// Declaration file for all the component object types. 
/// (all are in use expect trigger)
/// All components are accessable in dear_imgui editor
///

Component_Flag :: enum u16 {
    Name, 
    Transform,
    Sprite,
    Collider,
    Rigid_Body,
    Interactable,
    Trigger,
    Script,
    Animator,
    Inventory
}

// Give the bit pattern for this component type
ComponentMask :: proc(_flag : Component_Flag) -> u16 {
    return u16(1) << u16(_flag)
}

// Name of the entity
Name :: struct {
    entityName : string,
}

// Standard 2D transform
Transform :: struct {
    pos : math.Vector2f32,
    rot : f32,
}

Sprite :: struct {
    texture : renderdata.Texture_Handle,
    // Used to dictate a smaller rect for the sprite to sample from a sprite sheet,
    uv_min : [2]f32, 
    // Used to dictate a smaller rect for the sprite to sample from a sprite sheet,
    uv_max : [2]f32,
    size : math.Vector2f32,
    color : [4]f32, 
    origin : [2]f32,
    layer : i32,
}

Collider_Shape :: enum u8 {
    Box, 
    Circle,
}

// The physics collider for the entity (box/circle only)
Collider :: struct {
    shape : Collider_Shape,
    half_extends : math.Vector2f32,
    radius : f32,
    is_trigger : bool,
}

// Box2D Physics rigid body type
Rigid_Body_Type :: enum u8 {
    Static,
    Dynamic,
    Kinematic
}

// Box2D Physics rigid body 
Rigid_Body :: struct {
    body_type : Rigid_Body_Type,
    fixed_rotation : bool, // No rotation cause isometric
    linear_damping : f32, // Small amount of resistance to help with movement feel
    gravity_scale : f32, // No gravity cause isometric
}

// Mouse over interactable, left-click to interact
Interactable :: struct {
    prompt_text : string,
    interaction_radius : f32,
    popup_offset_y : f32,
    enabled : bool,
}

Trigger :: struct {

}

// The script component that runs gameplay logic when attached to an entity
Script :: struct {
    path : string,
    enabled : bool,
    hot_reload : bool,
}

// Contains the references required to run the animator component
Animator :: struct {
    anim_player : animation.Animation_Player,
    requested_state : string, // Reference to the anim clip to play
    current_state : string, // Path to the animation it's currently playing
    applied_direction : animation.Animation_Direction,
    bank : ^animation.Animation_Bank,
} 

// The inventory allowing player to collect gold for the minecart.
Inventory :: struct {
    gold : i32,
    capacity : i32 // 0 means unlimited capacity
}
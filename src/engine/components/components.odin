package components

import math "core:math/linalg"

Component_Flag :: enum u16 {
    Name, 
    Transform,
    Sprite,
    Collider,
    Rigid_Body,
    Interactable,
    Trigger,
    Script,
}

// Give the bit pattern for this component type
ComponentMask :: proc(_flag : Component_Flag) -> u16 {
    return u16(1) << u16(_flag)
}

Name :: struct {

}

Transform :: struct {
    pos : math.Vector2f32,
    rot : f32,
}

Sprite :: struct {
    // texture 
    
}

Collider :: struct {

}

Rigid_Body :: struct {

}

Interactable :: struct {

}

Trigger :: struct {

}

Script :: struct {

}
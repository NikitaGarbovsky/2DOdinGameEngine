package components

import math "core:math/linalg"
import renderdata "../renderdata"

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
    entityName : string,
}

Transform :: struct {
    pos : math.Vector2f32,
    rot : f32,
}

Sprite :: struct {
    texture : renderdata.Texture_Handle,
    // min & max are used to dictate a smaller rect for the sprite to sample from,
    // for future sprite sheets, animation, optimizations of gpu texture sending etc..
    // #TODO: Use this for animation when implemented!
    uv_min : [2]f32, 
    uv_max : [2]f32,
    size : math.Vector2f32,
    color : [4]f32, 
    origin : [2]f32,
    layer : i32,
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
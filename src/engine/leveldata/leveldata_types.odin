package leveldata

import components "../components"

///
/// Contains the type definitions for the level data that needs to be saved.
///

// Represents the data for a loaded/savable level
Level_File :: struct {
    version : u32,
    tile_layers : [dynamic]Tile_Layer_Data, 
    entities : [dynamic]Entity_Instance_Data, 
}

// Mapped json object holding
Tile_Layer_Data :: struct {
    name : string,
    tiles : [dynamic]Tile_Placement_Data,
}

// Mapped json object representing a single tiles placement
Tile_Placement_Data :: struct {
    x : i32,
    y : i32,
    tile : string,
}

// Definition for kind of entity this is for saving
Entity_Kind :: enum u8 {
    Minecart,
    Gold_Ingot,
}

// Contains all the entity data that will be saved in the level file.
Entity_Instance_Data :: struct {
    kind : Entity_Kind,
    name : string,

    pos : [2]f32,
    rot : f32,

    // #TODO: this probably doesn't need to be saved but its fine for now
    sprite_size : [2]f32,
    sprite_color : [4]f32,
    sprite_origin : [2]f32,
    sprite_uv_min : [2]f32,
    sprite_uv_max : [2]f32,
    sprite_layer : i32,

    collider_shape : components.Collider_Shape,
    collider_half_extends : [2]f32,
    collider_radius : f32,
    collider_is_trigger : bool,

    rb_body_type : components.Rigid_Body_Type,
    rb_fixed_rotation : bool,
    rb_linear_damping : f32,
    rb_gravity_scale : f32,

    interactable_prompt_text : string,
    interactable_radius : f32,
    interactable_popup_offset_y : f32,
    interactable_enabled : bool,

    script_path : string,
    script_enabled : bool,
    script_hot_reload : bool,

    inventory_gold : i32,
    inventory_capacity : i32,
}
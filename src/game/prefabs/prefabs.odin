#+vet explicit-allocators
package prefabs

import "../../engine/ecs"
import "../../engine/leveldata"
import "../../engine/physics"
import "../../engine/components"
import "../../engine/animation"
import "../../engine/renderdata"

///
/// This file defines the premade entitys (prefabs) that the editor can spawn.
/// #TODO: this is not that great of a structure with so much duplicated code,
/// redesign this system at some point.
///

// Returns the type of spawnable entity this is. 
GetSavedEntityKind :: proc(
    _world : ^ecs.EntityWorld, 
    _entity : ecs.Entity
) -> (leveldata.Entity_Kind, bool) {
    script, ok := ecs.GetComponent(&_world.scripts, _entity)
    if !ok do return {}, false

    // #TODO: this is not very robust and not 
    // very scalable. 
    switch script.path {
    case "Resources/Scripts/Minecart.lua":
        return .Minecart, true
    case "Resources/Scripts/GoldPieceCollectable.lua":
        return .Gold_Ingot, true
    }

    return {}, false
}

// Maps components of an entity to the saved instance data.
// Used as a reference for loading entities into a scene.
BuildSavedEntityData :: proc(
    _world : ^ecs.EntityWorld, 
    _entity : ecs.Entity
) -> (leveldata.Entity_Instance_Data, bool) {
    kind, ok := GetSavedEntityKind(_world, _entity)
    if !ok do return {}, false

    out := leveldata.Entity_Instance_Data{}
    out.kind = kind

    if name, ok := ecs.GetComponent(&_world.names, _entity); ok {
        out.name = name.entityName
    }

    if transform, ok := ecs.GetComponent(&_world.transforms, _entity); ok {
        out.pos = {transform.pos.x, transform.pos.y}
        out.rot = transform.rot
    }

    if sprite, ok := ecs.GetComponent(&_world.sprites, _entity); ok {
        out.sprite_size = {sprite.size.x, sprite.size.y}
        out.sprite_color = sprite.color
        out.sprite_origin = sprite.origin
        out.sprite_uv_min = sprite.uv_min
        out.sprite_uv_max = sprite.uv_max
        out.sprite_layer = sprite.layer
    }

    if collider, ok := ecs.GetComponent(&_world.colliders, _entity); ok {
        out.collider_shape = collider.shape
        out.collider_half_extends = {collider.half_extends.x, collider.half_extends.y}
        out.collider_radius = collider.radius
        out.collider_is_trigger = collider.is_trigger
    }

    if rb, ok := ecs.GetComponent(&_world.rigid_bodies, _entity); ok {
        out.rb_body_type = rb.body_type
        out.rb_fixed_rotation = rb.fixed_rotation
        out.rb_linear_damping = rb.linear_damping
        out.rb_gravity_scale = rb.gravity_scale
    }

    if interactable, ok := ecs.GetComponent(&_world.interactables, _entity); ok {
        out.interactable_prompt_text = interactable.prompt_text
        out.interactable_radius = interactable.interaction_radius
        out.interactable_popup_offset_y = interactable.popup_offset_y
        out.interactable_enabled = interactable.enabled
    }

    if script, ok := ecs.GetComponent(&_world.scripts, _entity); ok {
        out.script_path = script.path
        out.script_enabled = script.enabled
        out.script_hot_reload = script.hot_reload
    }

    if inventory, ok := ecs.GetComponent(&_world.inventory, _entity); ok {
        out.inventory_gold = inventory.gold
        out.inventory_capacity = inventory.capacity
    }

    return out, true
}

// Adds all the currently loaded entities in the scene to the level file.
AppendPlacedEntitiesToLevelFile :: proc(
    _world: ^ecs.EntityWorld, 
    _file: ^leveldata.Level_File
) {
    for entity, alive in _world.alive {
        if !alive do continue

        entity_data, ok := BuildSavedEntityData(_world, entity)
        if ok {
            append(&_file.entities, entity_data)
        }
    }
}

// Created the gold ingot entity that players collect
CreateGoldIngotEntity :: proc(
    _world : ^ecs.EntityWorld,
    _physics : ^physics.PhysicsWorld,
    _spawnPos : [2]f32,
) -> ecs.Entity {
    interactableEntity := ecs.CreateEntity(_world)

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.names,
        interactableEntity,
        components.Name{entityName = "Gold Ingot"},
        .Name
    )

    idle_clip, ok_idle := animation.GetDirectionalClip(&animation.goldingot_anim_bank, "GoldIngotIdle", .South)
    first_frame := idle_clip.frames[0]  

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.sprites,
        interactableEntity,
        components.Sprite{
            texture = idle_clip.texture,
            uv_min  = first_frame.uv_min,
            uv_max  = first_frame.uv_max,
            size    = first_frame.size / 6,
            color   = {1, 1, 1, 1},
            origin  = first_frame.origin,
            layer   = renderdata.DEPTH_SORT_LAYER,
        },
        .Sprite,
    )

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.transforms,
        interactableEntity,
        components.Transform{
            pos = _spawnPos, 
            rot = 0
        },
        .Transform
    )

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.colliders,
        interactableEntity,
        components.Collider{
            shape = .Box,
            half_extends = {10, 10},
            radius = 0,
            is_trigger = false,
        },
        .Collider,
    )

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.scripts,
        interactableEntity,
        components.Script{
            path = "Resources/Scripts/GoldPieceCollectable.lua", 
            enabled = true,
            hot_reload = true,
        },
        .Script
    )

     ecs.AddComponentToEntityWorld(
        _world,
        &_world.rigid_bodies,
        interactableEntity,
        components.Rigid_Body{
            body_type = .Dynamic,
            fixed_rotation = true,
            linear_damping = 8.0,
            gravity_scale = 0.0,
        },
        .Rigid_Body,
    )

    transform, ok0 := ecs.GetComponent(&_world.transforms, interactableEntity); assert(ok0)
    rb, ok1 := ecs.GetComponent(&_world.rigid_bodies, interactableEntity); assert(ok1)
    col, ok2 := ecs.GetComponent(&_world.colliders, interactableEntity); assert(ok2)
    created := physics.CreateBodyForEntity(
        _physics,
        interactableEntity,
        transform,
        rb,
        col,
    )

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.interactables,
        interactableEntity,
        components.Interactable{
            prompt_text = "Gold Ingot",
            interaction_radius = 100,
            popup_offset_y = 20,
            enabled = true,
        },
        .Interactable
    )

    return interactableEntity
}

CreateMineCartEntity :: proc(
    _world : ^ecs.EntityWorld,
    _physics : ^physics.PhysicsWorld,
    _spawnPos : [2]f32,
) -> ecs.Entity {

    minecartEntity := ecs.CreateEntity(_world)

    idle_clip, ok_idle := animation.GetDirectionalClip(&animation.minecart_anim_bank, "MinecartIdle", .South)
    first_frame := idle_clip.frames[0]  

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.sprites,
        minecartEntity,
        components.Sprite{
            texture = idle_clip.texture,
            uv_min  = first_frame.uv_min,
            uv_max  = first_frame.uv_max,
            size    = first_frame.size * 0.8,
            color   = {1, 1, 1, 1},
            origin  = first_frame.origin,
            layer   = renderdata.DEPTH_SORT_LAYER,
        },
        .Sprite,
    )

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.names,
        minecartEntity,
        components.Name{entityName = "Minecart"},
        .Name,
    )

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.transforms,
        minecartEntity,
        components.Transform{
            pos = _spawnPos, 
            rot = 0
        },
        .Transform
    )

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.colliders,
        minecartEntity,
        components.Collider{
            shape = .Box,
            half_extends = {30, 20},
            radius = 0,
            is_trigger = false,
        },
        .Collider,
    )

     ecs.AddComponentToEntityWorld(
        _world,
        &_world.scripts,
        minecartEntity,
        components.Script{
            path = "Resources/Scripts/Minecart.lua", 
            enabled = true,
            hot_reload = true,
        },
        .Script
    )

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.interactables,
        minecartEntity,
        components.Interactable{
            prompt_text = "Minecart",
            interaction_radius = 100,
            popup_offset_y = 45,
            enabled = true,
        },
        .Interactable
    )

    ecs.AddComponentToEntityWorld(
        _world,
        &_world.inventory,
        minecartEntity,
        components.Inventory{
            gold = 0,
            capacity = 10,
        },
        .Inventory,
    )

     ecs.AddComponentToEntityWorld(
        _world,
        &_world.rigid_bodies,
        minecartEntity,
        components.Rigid_Body{
            body_type = .Dynamic,
            fixed_rotation = true,
            linear_damping = 500.0,
            gravity_scale = 0.0,
        },
        .Rigid_Body,
    )

    transform, ok0 := ecs.GetComponent(&_world.transforms, minecartEntity); assert(ok0)
    rb, ok1 := ecs.GetComponent(&_world.rigid_bodies, minecartEntity); assert(ok1)
    col, ok2 := ecs.GetComponent(&_world.colliders, minecartEntity); assert(ok2)
    created := physics.CreateBodyForEntity(
        _physics,
        minecartEntity,
        transform,
        rb,
        col,
    )

    return minecartEntity
}
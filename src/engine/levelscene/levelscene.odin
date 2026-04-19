#+vet explicit-allocators
package levelscene

import "core:log"
import "../tilemap"
import "../ecs"
import "../physics"
import "../leveldata"
import "../../game/prefabs"

///
/// This manages the levels scene, saving/loading of tilemap & entities.
///

// Saves all the level data 
SaveCurrentLevel :: proc(
    _level : ^tilemap.Level_State,
    _world : ^ecs.EntityWorld,
) -> bool {
    if _level.editor.current_level_path.len == 0 {
        log.warn("SaveCurrentLevel: no current level path set")
        return false
    }

    file := leveldata.Level_File{
        version     = 1,
        tile_layers = make([dynamic]leveldata.Tile_Layer_Data, 0, tilemap.TILEMAP_LAYER_COUNT),
        entities    = make([dynamic]leveldata.Entity_Instance_Data),
    }
    defer leveldata.DestroyLevelFile(&file)

    append(&file.tile_layers, tilemap.BuildTileLayerData(_level, .Ground))
    append(&file.tile_layers, tilemap.BuildTileLayerData(_level, .Walls))
    append(&file.tile_layers, tilemap.BuildTileLayerData(_level, .Decoration))

    prefabs.AppendPlacedEntitiesToLevelFile(_world, &file)

    path := tilemap.PathBuffer_String(&_level.editor.current_level_path)
    ok := leveldata.SaveLevelFile(path, file)
    if ok {
        log.infof("Saved full level: {}", path)
    }

    return ok
}

// Loads the level scene, all tilemap tiles & entities.
LoadLevelFromPath :: proc(
    _level : ^tilemap.Level_State,
    _world : ^ecs.EntityWorld,
    _physics : ^physics.PhysicsWorld,
    _path : string,
) -> bool {
    file, ok := leveldata.LoadLevelFile(_path)
    if !ok {
        return false
    }
    defer leveldata.DestroyLevelFile(&file)

    tilemap.ClearAllTileLayers(_level)

    for i := 0; i < len(file.tile_layers); i += 1 {
        layer_data := file.tile_layers[i]

        layer, ok := tilemap.TilemapLayerFromName(layer_data.name)
        if !ok {
            log.warnf("LoadLevelFromPath: unknown layer '{}', skipping", layer_data.name)
            continue
        }

        if !tilemap.ApplyTileLayerData(_level, layer, layer_data) {
            return false
        }
    }

    LoadPlacedEntitiesFromLevelFile(_world, _physics, &file)

    if !tilemap.PathBuffer_Set(&_level.editor.current_level_path, _path) {
        log.warnf("LoadLevelFromPath: loaded level, but failed to store current path '{}'", _path)
    }

    log.infof("Loaded full level: {}", _path)
    return true
}

// Loads all the manually placed entities from the level file.
LoadPlacedEntitiesFromLevelFile :: proc(
    _world : ^ecs.EntityWorld,
    _physics : ^physics.PhysicsWorld,
    _file : ^leveldata.Level_File,
) {
    DestroyPlacedLevelEntities(_world, _physics)

    for entity_data in _file.entities {
        spawned : ecs.Entity

        switch entity_data.kind {
        case .Minecart:
            spawned = prefabs.CreateMineCartEntity(_world, _physics, entity_data.pos)

        case .Gold_Ingot:
            spawned = prefabs.CreateGoldIngotEntity(_world, _physics, entity_data.pos)
        }

        ApplySavedEntityData(_world, _physics, spawned, entity_data)
    }
}


// Correctly destroys all current loaded entities in the level scene.
DestroyPlacedLevelEntities :: proc(
    _world : ^ecs.EntityWorld,
    _physics : ^physics.PhysicsWorld,
) {
    to_delete := make([dynamic]ecs.Entity)
    defer delete(to_delete)

    for entity, alive in _world.alive {
        if !alive do continue

        _, ok := prefabs.GetSavedEntityKind(_world, entity)
        if ok {
            append(&to_delete, entity)
        }
    }

    for entity in to_delete {
        physics.DestroyBodyForEntity(_physics, entity)
        ecs.DeleteEntity(_world, entity)
    }
}

// Assigns the loaded level data to the entity.
ApplySavedEntityData :: proc(
    _world : ^ecs.EntityWorld,
    _physics : ^physics.PhysicsWorld,
    _entity : ecs.Entity,
    _data : leveldata.Entity_Instance_Data,
) {
    if name, ok := ecs.GetComponent(&_world.names, _entity); ok {
        name.entityName = _data.name
    }

    if transform, ok := ecs.GetComponent(&_world.transforms, _entity); ok {
        transform.pos = {_data.pos[0], _data.pos[1]}
        transform.rot = _data.rot
    }

    if sprite, ok := ecs.GetComponent(&_world.sprites, _entity); ok {
        sprite.size   = {_data.sprite_size[0], _data.sprite_size[1]}
        sprite.color  = _data.sprite_color
        sprite.origin = _data.sprite_origin
        sprite.uv_min = _data.sprite_uv_min
        sprite.uv_max = _data.sprite_uv_max
        sprite.layer  = _data.sprite_layer
    }

    if collider, ok := ecs.GetComponent(&_world.colliders, _entity); ok {
        collider.shape        = _data.collider_shape
        collider.half_extends = {_data.collider_half_extends[0], _data.collider_half_extends[1]}
        collider.radius       = _data.collider_radius
        collider.is_trigger   = _data.collider_is_trigger
    }

    if rb, ok := ecs.GetComponent(&_world.rigid_bodies, _entity); ok {
        rb.body_type      = _data.rb_body_type
        rb.fixed_rotation = _data.rb_fixed_rotation
        rb.linear_damping = _data.rb_linear_damping
        rb.gravity_scale  = _data.rb_gravity_scale
    }

    if interactable, ok := ecs.GetComponent(&_world.interactables, _entity); ok {
        interactable.prompt_text        = _data.interactable_prompt_text
        interactable.interaction_radius = _data.interactable_radius
        interactable.popup_offset_y     = _data.interactable_popup_offset_y
        interactable.enabled            = _data.interactable_enabled
    }

    if script, ok := ecs.GetComponent(&_world.scripts, _entity); ok {
        script.path       = _data.script_path
        script.enabled    = _data.script_enabled
        script.hot_reload = _data.script_hot_reload
    }

    if inventory, ok := ecs.GetComponent(&_world.inventory, _entity); ok {
        inventory.gold     = _data.inventory_gold
        inventory.capacity = _data.inventory_capacity
    }

    // Rebuild physics body so loaded collider / rigidbody / transform values are applied.
    physics.DestroyBodyForEntity(_physics, _entity)

    transform, ok_t := ecs.GetComponent(&_world.transforms, _entity)
    rb,        ok_r := ecs.GetComponent(&_world.rigid_bodies, _entity)
    col,       ok_c := ecs.GetComponent(&_world.colliders, _entity)

    if ok_t && ok_r && ok_c {
        _ = physics.CreateBodyForEntity(
            _physics,
            _entity,
            transform,
            rb,
            col,
        )
    }
}



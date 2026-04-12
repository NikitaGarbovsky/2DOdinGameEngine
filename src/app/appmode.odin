package app 

import "../engine/ecs"
import "../engine/components"
import "../engine/editorimgui"
import "../engine/tilemap"
import "../engine/renderdata"
import "../engine/physics"
import "../engine/animation"
import "../engine/systems"
import "../engine/scripting"
import math "core:math/linalg"
import "core:fmt"

///
/// User can swap on the fly from editor -> play mode and back.
/// This manages that functionality and state changes, loads/unloads, initialzation
/// for that to occur
///

ToggleAppMode :: proc(_app : ^AppState) {
    switch _app.mode {
        case .Editor: 
            EnterPlaymode(_app)
        case .Playmode: 
            EnterEditormode(_app)
    }
}

EnterPlaymode :: proc(_app : ^AppState) {
    tilemap.ShutdownLevelEditorState(&_app.level)
    editorimgui.ShutdownEditorImgui()

    fmt.println("Entering playmode...")
    SpawnPlayer(_app)

    built := physics.BuildTilemapWallCollision(&_app.physics_world, &_app.level)
    fmt.println("Built wall collision:", built)
    
    scripting.InitializeScripting(&_app.script_runtime)
    _app.mode = .Playmode
}

EnterEditormode :: proc(_app : ^AppState) {
    scripting.ShutdownScripting(&_app.script_runtime)
    fmt.println("Entering editormode...")

	editorimgui.InitEditorImgui(_app.platform.window, _app.renderer.gpu, _app.renderer.swapchain_color_format, ._1)
	
    tilemap.InitLevelEditorState(&_app.level, &_app.renderer)
	InitFrameStats(&_app.stats)

    if _app.play_state.has_player {
        physics.DestroyBodyForEntity(&_app.physics_world, _app.play_state.player_entity)
    }

    physics.DestroyTilemapWallCollision(&_app.physics_world)
    // #TODO: probably change this to not destroy the player when returning to editor mode,
    // for editor functionality, probably want to user to choose whether to start the "level"
    // over again explicitly, rather than just resetting like this.
    DestroyPlayer(_app)
    _app.mode = .Editor
}

SpawnPlayer :: proc(_app : ^AppState) {
    if _app.play_state.has_player do return // Only spawn one player

    playerEntity := ecs.CreateEntity(&_app.world)

    _app.play_state.player_entity = playerEntity
    _app.play_state.has_player = true

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.names,
        playerEntity,
        components.Name{entityName = "Player"},
        .Name
    )

    // Assign idle clip to player, reference for sprite component bellow,
    idle_clip, ok_idle := animation.GetDirectionalClip(&animation.player_anim_bank, "PlayerIdle", .South)
    assert(ok_idle)
    first_frame := idle_clip.frames[0]

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.sprites,
        playerEntity,
        components.Sprite{
            texture = idle_clip.texture,
            uv_min  = first_frame.uv_min,
            uv_max  = first_frame.uv_max,
            size    = first_frame.size / 2,
            color   = {1, 1, 1, 1},
            origin  = first_frame.origin,
            layer   = renderdata.DEPTH_SORT_LAYER,
        },
        .Sprite,
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.transforms,
        playerEntity,
        components.Transform{
            pos = math.Vector2f32{1000, 1000}, // #TODO: Set the player position in the level file, reference it here on spawn.
            rot = 0
        },
        .Transform
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.colliders,
        playerEntity,
        components.Collider{
            shape = .Box,
            half_extends = {10, 8},
            radius = 0,
            is_trigger = false,
        },
        .Collider,
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.rigid_bodies,
        playerEntity,
        components.Rigid_Body{
            body_type = .Dynamic,
            fixed_rotation = true,
            linear_damping = 8.0,
            gravity_scale = 0.0,
        },
        .Rigid_Body,
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.animators,
        playerEntity,
        components.Animator{
            bank = &animation.player_anim_bank,
            requested_state = "PlayerIdle",
            current_state = "",
            applied_direction = .South,
            anim_player = animation.Animation_Player{
                current_clip = idle_clip,
                current_frame = 0,
                frame_timer = 0,
                per_frame_time = 0.05, // #TODO: Allow this to be configurable
                playing = true,
                speed = 1,
                just_finished = false,
                flip_x = false,
                current_direction = .South,
            },
        },
        .Animator
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.scripts,
        playerEntity,
        components.Script{
            path = "Resources/scripts/PlayerMovement.lua", // #TODO: Assign scripts through the editor gui.
            enabled = true,
            hot_reload = true,
        },
        .Script
    )
 
    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.inventory,
        playerEntity,
        components.Inventory{
            gold = 0,
            capacity = 0
        },
        .Inventory
    )

    transform, ok0 := ecs.GetComponent(&_app.world.transforms, _app.play_state.player_entity); assert(ok0)
    rb, ok1 := ecs.GetComponent(&_app.world.rigid_bodies, _app.play_state.player_entity); assert(ok1)
    col, ok2 := ecs.GetComponent(&_app.world.colliders, _app.play_state.player_entity); assert(ok2)
    created := physics.CreateBodyForEntity(
        &_app.physics_world,
        _app.play_state.player_entity,
        transform,
        rb,
        col,
    )
    fmt.println("Created player physics body:", created)
}

DestroyPlayer :: proc(_app : ^AppState) {
    if !_app.play_state.has_player do return

    ecs.DeleteEntity(&_app.world, _app.play_state.player_entity)
    _app.play_state.has_player = false
}

// #TODO: TEMP JUST TO TEST INTERACTABLE ENTITIES.
CreateTestingInteractableEntity :: proc(_app : ^AppState, _spawnPos : [2]f32 = {1000, 1000}) {
    interactableEntity := ecs.CreateEntity(&_app.world)

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.names,
        interactableEntity,
        components.Name{entityName = "GoldIngot"},
        .Name
    )

    idle_clip, ok_idle := animation.GetDirectionalClip(&animation.goldingot_anim_bank, "GoldIngotIdle", .South)
    first_frame := idle_clip.frames[0]  

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.sprites,
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
        &_app.world,
        &_app.world.transforms,
        interactableEntity,
        components.Transform{
            pos = _spawnPos, 
            rot = 0
        },
        .Transform
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.colliders,
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
        &_app.world,
        &_app.world.scripts,
        interactableEntity,
        components.Script{
            path = "Resources/scripts/GoldPieceCollectable.lua", 
            enabled = true,
            hot_reload = true,
        },
        .Script
    )

     ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.rigid_bodies,
        interactableEntity,
        components.Rigid_Body{
            body_type = .Dynamic,
            fixed_rotation = true,
            linear_damping = 8.0,
            gravity_scale = 0.0,
        },
        .Rigid_Body,
    )

    transform, ok0 := ecs.GetComponent(&_app.world.transforms, interactableEntity); assert(ok0)
    rb, ok1 := ecs.GetComponent(&_app.world.rigid_bodies, interactableEntity); assert(ok1)
    col, ok2 := ecs.GetComponent(&_app.world.colliders, interactableEntity); assert(ok2)
    created := physics.CreateBodyForEntity(
        &_app.physics_world,
        interactableEntity,
        transform,
        rb,
        col,
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.interactables,
        interactableEntity,
        components.Interactable{
            prompt_text = "Hello!",
            interaction_radius = 100,
            popup_offset_y = 20,
            enabled = true,
        },
        .Interactable
    )


}

CreateMineCartEntity :: proc(_app : ^AppState, _spawnPos : [2]f32) {

    minecartEntity := ecs.CreateEntity(&_app.world)

    idle_clip, ok_idle := animation.GetDirectionalClip(&animation.minecart_anim_bank, "MinecartIdle", .South)
    first_frame := idle_clip.frames[0]  

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.sprites,
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
        &_app.world,
        &_app.world.transforms,
        minecartEntity,
        components.Transform{
            pos = _spawnPos, 
            rot = 0
        },
        .Transform
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.colliders,
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
        &_app.world,
        &_app.world.scripts,
        minecartEntity,
        components.Script{
            path = "Resources/Scripts/Minecart.lua", 
            enabled = true,
            hot_reload = true,
        },
        .Script
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.interactables,
        minecartEntity,
        components.Interactable{
            prompt_text = "Hello!",
            interaction_radius = 100,
            popup_offset_y = 20,
            enabled = true,
        },
        .Interactable
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.inventory,
        minecartEntity,
        components.Inventory{
            gold = 0,
            capacity = 10,
        },
        .Inventory,
    )

     ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.rigid_bodies,
        minecartEntity,
        components.Rigid_Body{
            body_type = .Dynamic,
            fixed_rotation = true,
            linear_damping = 500.0,
            gravity_scale = 0.0,
        },
        .Rigid_Body,
    )

    transform, ok0 := ecs.GetComponent(&_app.world.transforms, minecartEntity); assert(ok0)
    rb, ok1 := ecs.GetComponent(&_app.world.rigid_bodies, minecartEntity); assert(ok1)
    col, ok2 := ecs.GetComponent(&_app.world.colliders, minecartEntity); assert(ok2)
    created := physics.CreateBodyForEntity(
        &_app.physics_world,
        minecartEntity,
        transform,
        rb,
        col,
    )
}
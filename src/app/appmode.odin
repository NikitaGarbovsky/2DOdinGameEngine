package app 

import "../engine/ecs"
import "../engine/components"
import "../engine/editorimgui"
import "../engine/tilemap"
import "../engine/renderdata"
import "../engine/physics"
import "../engine/animation"
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
    animation_player : animation.Animation_Player
    animation_player.current_clip = animation.player_anim_bank.animation_clips[8]
    animation_player.per_frame_time = 0.2
    animation_player.current_clip.looping = true
    _app.play_state.animation_player = animation_player

    fmt.println("Entering playmode...")
    SpawnPlayer(_app)

    built := physics.BuildTilemapWallCollision(&_app.physics_world, &_app.level)
    fmt.println("Built wall collision:", built)
    
    _app.mode = .Playmode
}

EnterEditormode :: proc(_app : ^AppState) {
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
    _app.play_state.move_speed = 220

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.names,
        playerEntity,
        components.Name{entityName = "Player"},
        .Name
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.sprites,
        playerEntity,
        components.Sprite{
            texture = renderdata.Default_Texture_Handle,
            uv_min  = {0, 0},
            uv_max  = {1, 1},
            size    = math.Vector2f32{28, 40},
            color   = {0.2, 0.9, 0.35, 1.0},
            origin  = {0.5, 1.0},
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
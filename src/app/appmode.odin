#+vet explicit-allocators
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
import "../engine/gameplayGUI"
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
    
    // Re syncs all rigidbodies that exist (so editor transform updates are persistent)
    SyncAllEntityBodiesFromECS(_app)

    scripting.InitializeScripting(&_app.script_runtime)
    gameplayGUI.InitGameplayGUI(
        &_app.play_state.gameplay_ui,
        &_app.renderer,
        f32(_app.platform.width),
        f32(_app.platform.height),
    )

    _app.renderer.clear_color = {0, 0, 0, 1.0} // #TODO: move this into the editor under some editor settings
    
    _app.mode = .Playmode
}

EnterEditormode :: proc(_app : ^AppState) {
    scripting.ShutdownScripting(&_app.script_runtime)
    gameplayGUI.ShutdownGameplayUI(&_app.play_state.gameplay_ui)
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
    
    _app.renderer.clear_color = {0.0, 0.2, 0.4, 1.0} // #TODO: move this into the editor under some editor settings

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
            path = "Resources/Scripts/PlayerMovement.lua", // #TODO: Assign scripts through the editor gui.
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



SyncAllEntityBodiesFromECS :: proc(_app: ^AppState) {
    // Iterate all entities that have rigid bodies
    for entity in _app.world.rigid_bodies.entities {
        transform, ok_t := ecs.GetComponent(&_app.world.transforms, entity)
        rb,       ok_r := ecs.GetComponent(&_app.world.rigid_bodies, entity)
        col,      ok_c := ecs.GetComponent(&_app.world.colliders, entity)
        if !(ok_t && ok_r && ok_c) do continue

        // Make sure old body can't override the edited transform
        physics.DestroyBodyForEntity(&_app.physics_world, entity) 

        _ = physics.CreateBodyForEntity(
            &_app.physics_world,
            entity,
            transform,
            rb,
            col,
        )
    }
}


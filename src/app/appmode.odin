package app 

import "../engine/ecs"
import "../engine/components"
import "../engine/editorimgui"
import "../engine/tilemap"
import "../engine/renderdata"
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
    fmt.println("Entering playmode...")
    
    tilemap.ShutdownLevelEditorState(&_app.level)
    editorimgui.ShutdownEditorImgui()

    SpawnPlayer(_app)
    _app.mode = .Playmode
}

EnterEditormode :: proc(_app : ^AppState) {
    fmt.println("Entering editormode...")

	editorimgui.InitEditorImgui(_app.platform.window, _app.renderer.gpu, _app.renderer.swapchain_color_format, ._1)
	
    tilemap.InitLevelEditorState(&_app.level, &_app.renderer)
	InitFrameStats(&_app.stats)

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
            layer   = 0,
        },
        .Sprite,
    )

    ecs.AddComponentToEntityWorld(
        &_app.world,
        &_app.world.transforms,
        playerEntity,
        components.Transform{
            pos = math.Vector2f32{500, 500}, // #TODO: Set the player position in the level file, reference it here on spawn.
            rot = 0
        },
        .Transform
    )
}

DestroyPlayer :: proc(_app : ^AppState) {
    if !_app.play_state.has_player do return

    ecs.DeleteEntity(&_app.world, _app.play_state.player_entity)
    _app.play_state.has_player = false
}
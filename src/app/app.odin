package app

import "../platform"
import "../engine/ecs"
import "../engine/renderer"
import "../engine/systems"
import "../engine/tilemap"
import "../engine/renderdata"
import "../engine/editorimgui"
import "../engine/input"
import "../engine/physics"

///
/// This is the main connecting manager of the engine. It connects windowing, rendering and editor 
/// functionality into one place. 
///
/// Runs the main loop of the engine. Runs System logic  
///


// Temp shader loading
shader_frag_batch := #load("../../Resources/Shaders/sprite_batch.frag.spv")
shader_vert_batch := #load("../../Resources/Shaders/sprite_batch.vert.spv")

Init :: proc(_app : ^AppState) {

	// ======== Initialize all the part's of the engine ========
	platform.Init(&_app.platform)
	ecs.Init(&_app.world)
	renderer.Init(&_app.renderer, &_app.platform, shader_vert_batch, shader_frag_batch)
	tilemap.InitLevelState(&_app.level,64,32)
	tilemap.InitCaveTileResources(&_app.level, &_app.renderer)
	physics.Init(&_app.physics_world)

	// Starting camera values
	_app.renderer.camera.position = {960, 540}
	_app.renderer.camera.zoom = 1.5

	// Default to editor mode, also initializes editor.
	EnterEditormode(_app) 
}

// Runs the main loop of the application, depending on the current app state.
Run :: proc(_app : ^AppState) {
	for _app.platform.running {
		TickFrameStats(&_app.stats) // Update frame rate details 

		// Create callback for editor imgui input detection
		event_callback := input.Event_Callback(nil)
		if _app.mode == .Editor {
			event_callback = editorimgui.EditorImgui_SDL3_ProcessEvent
		}

		// Process SDL input
		input.ProcessSDLEvents(&_app.input, &_app.platform.running, &_app.platform.width, &_app.platform.height,
			event_callback,) // <-- Callback, this is just null when not in editor mode 

		// Before any rendering, pass the 
		if _app.input.toggle_appmode_pressed { 
			ToggleAppMode(_app)
		}

		// Renders the scene and all the render passes.
		if renderer.BeginFrame(&_app.renderer, {f32(_app.platform.width), f32(_app.platform.height)}) {
			
			if _app.mode == .Editor {
				editorContext = systems.Editor_Mode_Context{
					input_state = &_app.input,
					frame_stats = &_app.stats,
					level_state = &_app.level,
					entity_world = &_app.world,
					renderer = &_app.renderer,
				}
				systems.RenderEditorMode(editorContext) 
			}
			if _app.mode == .Playmode {
					playContext := systems.Play_Mode_Context{
						input_state = &_app.input,
						frame_stats = &_app.stats,
						entity_world = &_app.world,
						renderer = &_app.renderer,
						player_entity = _app.play_state.player_entity,
						has_player = _app.play_state.has_player,
						move_speed = _app.play_state.move_speed,
						physics_world = &_app.physics_world
				}
				systems.UpdatePlayMode(playContext)
				physics.Step(&_app.physics_world, _app.stats.deleta_seconds)
				physics.SyncTransformsFromPhysics(&_app.physics_world, &_app.world)

				if transform, ok := ecs.GetComponent(&_app.world.transforms, _app.play_state.player_entity); ok {
					_app.renderer.camera.position = transform.pos
				}
			}
	
			// This is "BeginWorldPass" with culling + batching attached on
			systems.RenderWorld(&_app.world, &_app.level ,&_app.renderer)
			renderer.EndPass(&_app.renderer)

			if _app.mode == .Editor {
				systems.EditorUIPass(editorContext) 
			}
			
			// Push all accumulated frame data to GPU
			renderer.EndFrame(&_app.renderer)
		}
	}
}

Shutdown :: proc(_app : ^AppState) {
	renderer.Shutdown(&_app.renderer)
	platform.Shutdown(&_app.platform)
	physics.Shutdown(&_app.physics_world)
}

package app

import math "core:math/linalg"

import "../platform"
import "../engine/ecs"
import "../engine/renderer"
import "../engine/systems"
import "../engine/assets"
import "../engine/tilemap"
import "../engine/renderdata"
import "../engine/editorimgui"
import "../engine/input"

// Temp shader loading
shader_frag_batch := #load("../../Resources/Shaders/sprite_batch.frag.spv")
shader_vert_batch := #load("../../Resources/Shaders/sprite_batch.vert.spv")

Init :: proc(_app : ^AppState) {

	// Initialize all the systems of the application
	platform.Init(&_app.platform)
	ecs.Init(&_app.world)
	renderer.Init(&_app.renderer, &_app.platform, shader_vert_batch, shader_frag_batch)
	tilemap.InitLevelState(&_app.level,64,32)
	editorimgui.InitEditorImgui(_app.platform.window, _app.renderer.gpu, _app.renderer.swapchain_color_format, ._1)

	InitFrameStats(&_app.stats)

	// ============== TEMP SPRITE LOADING ============== 
	sprite_path := "Resources/Sprites/tileset_cave_1.png"
	image, ok := assets.LoadImageFile(sprite_path); assert(ok)
	defer assets.DestroyImage(&image)

	sprite_texture, ok2 := renderer.CreateTextureFromImage(&_app.renderer, image); assert(ok2)

	// ================== TEMP TILE TESTING ==================
	tilemap.RegisterTileDef(&_app.level.defs, &tilemap.Tile_Definition{
		key = "ground",
		texture = sprite_texture,
		sampler = renderdata.Default_Sampler_Handle,
		uv_min = {0, 0.03125},
		uv_max = {0.0625,0.0625},
		size = {64, 32},
		origin = {0.5, 0.5},
		layer = 0,
		collision = .None,
	})
	ground_id, _ := tilemap.FindTileDefByKey(&_app.level.defs, "ground")
	tilemap.SelectTileForPainting(&_app.level, ground_id)

	// Temp setting for camera testing, #TODO: remove when input(mouse scroll/camera zoom) is implemented
	_app.renderer.camera.position = {960, 540}
	_app.renderer.camera.zoom = 2
}

// Runs the main loop of the application, depending on the current app state.
Run :: proc(_app : ^AppState) {
	for _app.platform.running {

		// Process sdl input
		input.ProcessSDLEvents(&_app.input,
			&_app.platform.running,
			&_app.platform.width,
			&_app.platform.height,
			editorimgui.EditorImgui_SDL3_ProcessEvent
		)

		// Capture any ui input first, before anything else
		ui_capture := editorimgui.GetInputCapture()
		editor_input := tilemap.Tilemap_Editor_Input{
			mouse_screen   = {_app.input.mouse_x, _app.input.mouse_y},
			left_clicked   = _app.input.left_pressed && !ui_capture.mouse,
			delete_pressed = _app.input.delete_pressed && !ui_capture.keyboard,
		}

		// Do tilemap editor updates 
		tilemap.UpdateEditor(&_app.level, &_app.renderer.camera, editor_input)

		viewport_size : math.Vector2f32
		viewport_size.x = f32(_app.platform.width)
		viewport_size.y = f32(_app.platform.height)

		// Renders the scene and all the render passes.
		if renderer.BeginFrame(&_app.renderer, viewport_size) {
			editorimgui.EditorImgui_BeginFrame()

			// Build UI widgets
			editorimgui.DrawAssetBrowser()

			// Finalize + upload imgui buffers BEFORE any render pass
    		imgui_draw_data := editorimgui.EditorImgui_Prepare(_app.renderer.cmd_buf)

			// This is "BeginWorldPass" with culling + batching attached on
			systems.RenderWorld(&_app.world, &_app.level ,&_app.renderer)
			renderer.EndPass(&_app.renderer)

			ui_pass := renderer.BeginEditorUIPass(&_app.renderer)
			if ui_pass != nil {
				editorimgui.EditorImgui_Render(imgui_draw_data, _app.renderer.cmd_buf, ui_pass)
				renderer.EndPass(&_app.renderer)
			}
			renderer.EndFrame(&_app.renderer)
		}

		TickFrameStats(&_app.stats)
	}
}

Shutdown :: proc(app : ^AppState) {
	renderer.Shutdown(&app.renderer)
	platform.Shutdown(&app.platform)
}

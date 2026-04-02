package app

import "../platform"
import "../engine/ecs"
import "../engine/renderer"
import "../engine/systems"
import "../engine/tilemap"
import "../engine/renderdata"
import "../engine/editorimgui"
import "../engine/input"

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

	// Editor
	editorimgui.InitEditorImgui(_app.platform.window, _app.renderer.gpu, _app.renderer.swapchain_color_format, ._1)
	tilemap.InitEditorPallete_Cave(&_app.level, &_app.renderer)
	InitFrameStats(&_app.stats)

	// Temp setting for camera testing, #TODO: remove when input(mouse scroll/camera zoom) is implemented
	_app.renderer.camera.position = {960, 540}
	_app.renderer.camera.zoom = 1.5
}

// Runs the main loop of the application, depending on the current app state.
Run :: proc(_app : ^AppState) {
	for _app.platform.running {

		// Process SDL input
		input.ProcessSDLEvents(&_app.input, &_app.platform.running, &_app.platform.width, &_app.platform.height,
			editorimgui.EditorImgui_SDL3_ProcessEvent)

		// Level Load/Save is async in sdl3, so we call this everyframe to catch the 
		// callbacks execution when their results occur. Refer to tilemapfiledialog.odin
		tilemap.PumpPendingDialogResults(&_app.level) 

		// Renders the scene and all the render passes.
		if renderer.BeginFrame(&_app.renderer, {f32(_app.platform.width), f32(_app.platform.height)}) {
			editorimgui.EditorImgui_BeginFrame()

			// Build UI widgets
			editorimgui.DrawAssetBrowser() 
			editorimgui.UpdateEditorDebugInfo(_app.stats.fps, _app.stats.ms_per_frame, _app.renderer.batchCountThisFrame, 
				_app.renderer.renderedWorldElementsThisFrame, _app.renderer.totalRenderedElementsThisFrame, 
				_app.renderer.culledEntityElementsThisFrame, _app.renderer.culledTilemapElementsThisFrame)
			editorimgui.DrawDebugInfo()

			tilemap.DrawEditorUI(&_app.level)
			
			if _app.level.editor.palette_open { // Only enable if tilepalette in editor is open.
				// Capture any ui input first, before anything else
				ui_capture := editorimgui.GetInputCapture()
				editor_input := tilemap.Tilemap_Editor_Input{
					mouse_screen = {_app.input.mouse_x, _app.input.mouse_y},
					mouse_delta = {_app.input.mouse_dx, _app.input.mouse_dy},
					mouse_scroll_down = _app.input.mouse_scroll_down,
					mouse_scroll_up = _app.input.mouse_scroll_up,

					left_clicked = _app.input.left_pressed && !ui_capture.mouse,
					right_down = _app.input.right_down,
					delete_pressed = _app.input.delete_pressed && !ui_capture.keyboard,
					space_down = _app.input.space_down,
					mouse_captured = ui_capture.mouse,
    				keyboard_captured = ui_capture.keyboard,}

				// Do tilemap frame-dependant editor updates 
				tilemap.UpdateEditor(&_app.level, &_app.renderer.camera, editor_input)
			}
		
			// Finalize + upload imgui buffers BEFORE any render pass, has to occur here.
    		imgui_draw_data := editorimgui.EditorImgui_Prepare(_app.renderer.cmd_buf)

			// This is "BeginWorldPass" with culling + batching attached on
			systems.RenderWorld(&_app.world, &_app.level ,&_app.renderer)
			renderer.EndPass(&_app.renderer)

			// Finish with UI pass
			ui_pass := renderer.BeginEditorUIPass(&_app.renderer)
			if ui_pass != nil {
				editorimgui.EditorImgui_Render(imgui_draw_data, _app.renderer.cmd_buf, ui_pass)
				renderer.EndPass(&_app.renderer)
			}
			
			// Push all frame data to GPU
			renderer.EndFrame(&_app.renderer)
		}

		TickFrameStats(&_app.stats) // Update frame rate details 
	}
}

Shutdown :: proc(_app : ^AppState) {
	renderer.Shutdown(&_app.renderer)
	platform.Shutdown(&_app.platform)
}

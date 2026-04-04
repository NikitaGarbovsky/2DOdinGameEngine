package systems

import imgui "Dependencies:odin-imgui"

import "../editorimgui"
import "../renderer"
import "../tilemap"
import "../input"
import "../ecs"

/// A system is a smaller alotment of functionality that is run by main application within it's main loop.

///
/// This system runs the editor mode functionality. It collects various resources from the rest of the
/// engine and utilizes it for running editor logic.
///


// Used to pass a bunch of references of the state of the engine from app to here 
Editor_Mode_Context :: struct {
    input_state : ^input.InputState,
    frame_stats : ^Frame_Stats,
    level_state : ^tilemap.Level_State,
    entity_world : ^ecs.EntityWorld,
    renderer : ^renderer.Renderer,
}

Frame_Stats :: struct {
    freq : u64,
    last_counter : u64,
    accum_seconds : f64,
    frame_count : i32,
    fps : f64,
    ms_per_frame: f64,
}
imgui_draw_data : ^imgui.Draw_Data

RenderEditorMode :: proc(_context : Editor_Mode_Context) {
    // Level Load/Save is async in sdl3, so we call this everyframe to catch the 
    // callbacks execution when their results occur. Refer to tilemapfiledialog.odin
    tilemap.PumpPendingDialogResults(_context.level_state) 

    editorimgui.EditorImgui_BeginFrame()

        // Build UI widgets
        editorimgui.DrawAssetBrowser() 
        editorimgui.UpdateEditorDebugInfo(
            _context.frame_stats.fps, 
            _context.frame_stats.ms_per_frame, 
            _context.renderer.batchCountThisFrame, 
            _context.renderer.renderedWorldElementsThisFrame, 
            _context.renderer.totalRenderedElementsThisFrame, 
            _context.renderer.culledEntityElementsThisFrame, 
            _context.renderer.culledTilemapElementsThisFrame
        )
        editorimgui.DrawDebugInfo()

        tilemap.DrawEditorUI(_context.level_state)
        
        if _context.level_state.editor.palette_open { // Only enable if tilepalette in editor is open.
            // Capture any ui input first, before anything else
            ui_capture := editorimgui.GetInputCapture()
            editor_input := tilemap.Tilemap_Editor_Input{
                mouse_screen = { _context.input_state.mouse_x, _context.input_state.mouse_y},
                mouse_delta = { _context.input_state.mouse_dx, _context.input_state.mouse_dy},
                mouse_scroll_down = _context.input_state.mouse_scroll_down,
                mouse_scroll_up =  _context.input_state.mouse_scroll_up,

                left_clicked =  _context.input_state.left_pressed && !ui_capture.mouse,
                right_down =  _context.input_state.right_down,
                delete_pressed =  _context.input_state.delete_pressed && !ui_capture.keyboard,
                space_down =  _context.input_state.space_down,
                mouse_captured = ui_capture.mouse,
                keyboard_captured = ui_capture.keyboard,}

            // Do tilemap frame-dependant editor updates 
            tilemap.UpdateEditor(_context.level_state, &_context.renderer.camera, editor_input)
        }
    
        // Finalize + upload imgui buffers BEFORE any render pass, has to occur here.
        imgui_draw_data = editorimgui.EditorImgui_Prepare(_context.renderer.cmd_buf)
}

EditorUIPass :: proc(_context : Editor_Mode_Context) {
    // Finish with UI pass
    ui_pass := renderer.BeginEditorUIPass(_context.renderer)
    if ui_pass != nil {
        editorimgui.EditorImgui_Render(imgui_draw_data, _context.renderer.cmd_buf, ui_pass)
        renderer.EndPass(_context.renderer)
    }
}
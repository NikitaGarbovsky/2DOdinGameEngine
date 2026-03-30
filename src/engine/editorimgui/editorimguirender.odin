package editorimgui

import sdl "vendor:sdl3"
import imgui "Dependencies:odin-imgui"
import imgui_impl_sdl3 "Dependencies:odin-imgui/imgui_impl_sdl3"
import imgui_impl_sdlgpu3 "Dependencies:odin-imgui/imgui_impl_sdlgpu3"

///
/// Contains the main required frame-by-frame imgui implementation details called by app
///


// Called to begin imgui frame
EditorImgui_BeginFrame :: proc() {
    assert(imgui.get_current_context() != nil)
    
    imgui_impl_sdlgpu3.new_frame()
    imgui_impl_sdl3.new_frame()
    imgui.new_frame()
}

// Prepares the imgui render data before a renderpass has started.
EditorImgui_Prepare :: proc(_cmd_buf : ^sdl.GPUCommandBuffer) -> ^imgui.Draw_Data {
    assert(imgui.get_current_context() != nil)
    assert(_cmd_buf != nil)
    
    imgui.render()

    draw_data := imgui.get_draw_data()
    if draw_data == nil do return nil
    if draw_data.display_size.x <= 0 || draw_data.display_size.y <= 0 do return nil

    imgui_impl_sdlgpu3.prepare_draw_data(draw_data, _cmd_buf)

    return draw_data
}

// Pushes the rendered elements to the command buffer bound to the renderpass
EditorImgui_Render :: proc(_draw_data: ^imgui.Draw_Data, _cmd_buf : ^sdl.GPUCommandBuffer, _render_pass : ^sdl.GPURenderPass) {
    assert(imgui.get_current_context() != nil)
    assert(_cmd_buf != nil)
    assert(_render_pass != nil)

    if _draw_data == nil do return

    imgui_impl_sdlgpu3.render_draw_data(_draw_data, _cmd_buf, _render_pass, nil)
}

// Used by sdl3 to yoink input (mouse/keyboard input, this is prioritized above editor functionality)
EditorImgui_SDL3_ProcessEvent :: proc(_event : ^sdl.Event) {
    imgui_impl_sdl3.process_event(_event)
}



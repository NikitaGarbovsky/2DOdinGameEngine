package editorimgui

import sdl "vendor:sdl3"
import imgui "Dependencies:odin-imgui"
import imgui_impl_sdl3 "Dependencies:odin-imgui/imgui_impl_sdl3"
import imgui_impl_sdlgpu3 "Dependencies:odin-imgui/imgui_impl_sdlgpu3"

/// 
/// The editorimgui package manages the dear_imgui editor UI used to use the engine 
/// part of the application. 
///


// Initializes editor imgui
InitEditorImgui :: proc(_window : ^sdl.Window, 
    _device : ^sdl.GPUDevice, 
    _tformat : sdl.GPUTextureFormat, 
    _sampleCount :sdl.GPUSampleCount) {

    ctx := imgui.create_context()
    imgui.set_current_context(ctx); assert(imgui.get_current_context() != nil)
    imgui.CHECKVERSION() // Validates compatibility of this imgui version

    // Load fonts before initializating backend
    io := imgui.get_io()
    s_editor_font := imgui.font_atlas_add_font_from_file_ttf(
        io.fonts, 
        "Resources/Fonts/AlteHaasGroteskRegular.ttf", 
        18.0, 
        nil, 
        imgui.font_atlas_get_glyph_ranges_default(io.fonts),
    )
    l_editor_font := imgui.font_atlas_add_font_from_file_ttf(
        io.fonts, 
        "Resources/Fonts/AlteHaasGroteskBold.ttf", 
        22.0, 
        nil,
        imgui.font_atlas_get_glyph_ranges_default(io.fonts),
    )

    // Init backends
    ok1 := imgui_impl_sdl3.init_for_sdlgpu(_window); assert(ok1)
    initinfo : imgui_impl_sdlgpu3.Init_Info = {_device, _tformat, _sampleCount}
    ok2 := imgui_impl_sdlgpu3.init(&initinfo); assert(ok2)
}

// Used by app to check if editor gui has used input (editorgui has priority) 
GetInputCapture :: proc() -> Input_Capture {
    io := imgui.get_io()
    return Input_Capture{
        mouse = io.want_capture_mouse,
        keyboard = io.want_capture_keyboard,
    }
}

// Called during the update loop, updates editor frame stats per frame.
UpdateEditorDebugInfo :: proc(_fps , _ms: f64, _batchCount : int, _worldRendererd, 
    _totalRendered : u32, _culledEntitySprites, _culledTiles : int) 
    {
    frameDebugInfo.framerate = _fps
    frameDebugInfo.ms = _ms
    frameDebugInfo.batchCount = _batchCount
    frameDebugInfo.renderedWorldElementsThisFrame = _worldRendererd
    frameDebugInfo.totalRenderedElementsThisFrame = _totalRendered
    frameDebugInfo.culledEntitySpriteThisFrame = _culledEntitySprites
    frameDebugInfo.culledTilemapSpriteThisFrame = _culledTiles
}

ShutdownEditorImgui :: proc() {
    imgui_impl_sdlgpu3.shutdown()
    imgui_impl_sdl3.shutdown()

    ctx := imgui.get_current_context()
    if ctx != nil {
        imgui.destroy_context(ctx)
    }
}
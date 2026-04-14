package gameplaygui

import clay "Dependencies:clay/clay-odin"
import "base:runtime"
import "core:log"
import "core:c"
import "../renderdata"

/// GameplayGUI is managed through the clay ui layout library. Resources 
/// are allocated upfront upon initialization, then widgets can be rendered 
/// during runtime. Widget definitions can be located in gameplayGUIWidgets.odin



// Initializes gameplayGUI
InitGameplayGUI :: proc(_ui : ^Clay_UI, _width, _height : f32) {
    if _ui.initialized do return

    // Allocate memory resources for clay
    mem_amount := clay.MinMemorySize()
    _ui.arena_mem = make([]u8, mem_amount, context.allocator)
    arena := clay.CreateArenaWithCapacityAndMemory(
        uint(len(_ui.arena_mem)),
        raw_data(_ui.arena_mem),
    )

    _ui.clay_ctx = clay.Initialize(
        arena,
        clay.Dimensions{width = _width, height = _height},
        clay.ErrorHandler{
            handler = ClayErrorHandler,
            userData = nil,},
    )
    // Initializes text measure callback 
    clay.SetMeasureTextFunction(MeasureText, nil)
    _ui.initialized = true
}

// Helper
ClayErrorHandler :: proc "c" (_error : clay.ErrorData) {
    context = runtime.default_context()
    log.errorf("Clay error: {}", _error.errorText )
}

// Helper
MeasureText :: proc "c" (
    _text : clay.StringSlice,
    _config : ^clay.TextElementConfig,
    _user_data : rawptr,
) -> clay.Dimensions {
    // #TODO: Use font metrics here

    text_str := string(_text.chars[:_text.length])

    char_w := f32(_config.fontSize) * 0.55
    return {
        width = f32(len(text_str)) * char_w,
        height = f32(_config.fontSize),
    }
}

// Helper that converts the computed clay layout item into a 
// render item for the rendering pipeline.
CreateGamplayGUIRenderItem :: proc(
    _bounds : clay.BoundingBox,
    _color : clay.Color,
) -> renderdata.Render_Item {
    // Create the color, normalized 0-1
    color := [4]f32{
        f32(_color[0]) / 255.0,
        f32(_color[1]) / 255.0,
        f32(_color[2]) / 255.0,
        f32(_color[3]) / 255.0,
    }

    // Creates a GUI render item from the clay layout data.
    return renderdata.Render_Item{
        pass = .UI,
        sort_layer = 0,
        y_sort = 0,

        material = renderdata.Material_Key{
            pipeline = .Sprite,
            texture = renderdata.Default_Texture_Handle,
            sampler = renderdata.Default_Sampler_Handle,
            blend = .Alpha,
        },

        instance = renderdata.Sprite_Instance{
            model = renderdata.MakeSpriteModelMatrix(
                {f32(_bounds.x), f32(_bounds.y)},
                {f32(_bounds.width), f32(_bounds.height)},
                {0, 0},
                0,
                0,
            ),
            uv_min = {0, 0},
            uv_max = {1, 1},
            color = color,
        },
    }
}

ShutdownGameplayUI :: proc(_ui : ^Clay_UI) {
    current := clay.GetCurrentContext()
    if current == _ui.clay_ctx {
        clay.SetCurrentContext(nil)
    }

    if len(_ui.arena_mem) > 0 {
        delete(_ui.arena_mem)
        _ui.arena_mem = nil
    }

    _ui.clay_ctx = nil
    _ui.initialized = false
}
package gameplaygui

import clay "Dependencies:clay/clay-odin"
import "base:runtime"
import "core:log"
import "core:c"
import "../renderdata"
import "vendor:sdl3/ttf"
import "core:strings"
import "../renderer"

/// GameplayGUI is managed through the clay ui layout library. Resources 
/// are allocated upfront upon initialization, then widgets can be rendered 
/// during runtime. Widget definitions can be located in gameplayGUIWidgets.odin



// Initializes gameplayGUI
InitGameplayGUI :: proc(_ui : ^Clay_UI, _renderer : ^renderer.Renderer, _width, _height : f32) {
    if _ui.initialized do return

    // Allocate memory resources for clay
    mem_amount := clay.MinMemorySize()
    _ui.arena_mem = make([]u8, mem_amount, context.allocator)
    arena := clay.CreateArenaWithCapacityAndMemory(
        uint(len(_ui.arena_mem)),
        raw_data(_ui.arena_mem),
    )

    // Initialize the font atlas #TODO: make font changable in editor.
    if !InitFontAtlas(
        _renderer,
        &_ui.gameplay_font,
        "Resources/Fonts/AlteHaasGroteskRegular.ttf",
        16,
        1024,
        1024,
    ) {
        log.error("Failed to initialize gameplay GUI font atlas")
        return
    }

    _ui.clay_ctx = clay.Initialize(
        arena,
        clay.Dimensions{width = _width, height = _height},
        clay.ErrorHandler{
            handler = ClayErrorHandler,
            userData = nil,},
    )

    // Initializes text measure callback 
    clay.SetMeasureTextFunction(MeasureText, &_ui.gameplay_font)
    _ui.initialized = true
}

// Helper
ClayErrorHandler :: proc "c" (_error : clay.ErrorData) {
    context = runtime.default_context()
    log.errorf("Clay error: {}", _error.errorText )
}

// Clay callback that uses SDL_ttf to measure text size.
MeasureText :: proc "c" (
    _text : clay.StringSlice,
    _config : ^clay.TextElementConfig,
    _user_data : rawptr,
) -> clay.Dimensions {
    context = runtime.default_context()

    // Returns early if there is no valid font atlas.
    atlas := (^Font_Atlas)(_user_data)
    if atlas == nil || atlas.font == nil {
        return {0, 0}
    }

    // Convert clay style slice into cstring for SDL_ttf
    text := string(_text.chars[:_text.length])
    text_c := strings.clone_to_cstring(text, context.temp_allocator)

    // Ask SDL_tff for the text width,
    w, h : i32
    ok := ttf.GetStringSize(
        atlas.font,
        text_c,
        c.size_t(_text.length),
        &w,
        &h,
    )
    if !ok {
        return {0, 0}
    }

    // Use the font's line height for layout
    line_h := ttf.GetFontLineSkip(atlas.font)
    if line_h <= 0 {
        line_h = ttf.GetFontHeight(atlas.font)
    }

    return clay.Dimensions{
        f32(w),
        f32(line_h),
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

// Creates render items for each character in a text string and adds them to the UI render list.
// Does some formating (kerning) for the font so it's spaced/formatted correctly.
AppendTextRenderItems :: proc(
    _atlas : ^Font_Atlas,
    _text : string,
    _x, _y : f32,
    _color : [4]f32,
    _items : ^[dynamic]renderdata.Render_Item,
) {
    // Current x position for where the next character will be drawn.
    pen_x : i32 = i32(_x)
    // Stores the previous character so kerning can be checked.
    prev : rune = 0

    // For each character in the text string,
    for char in _text {
        // Make sure glyph exists in the font atlas,
        glyph, ok := EnsureGlyphLoaded(_atlas, char)
        if !ok do continue

        kern : i32 = 0
        if prev != 0 {
            ttf.GetGlyphKerning(_atlas.font, u32(prev), u32(char), &kern)
        }

        // Apply kerning and place the glyph quad at the current pen position.
        glyph_x : i32 = pen_x + kern 
        glyph_y : i32 = i32(_y)

        // Add the character as a render item to the render list.
        append(_items, renderdata.Render_Item{
            pass = .UI,
            sort_layer = 1,
            y_sort = 0,
            material = renderdata.Material_Key{
                pipeline = .Sprite,
                texture = _atlas.texture,
                sampler = _atlas.sampler,
                blend = .Alpha,
            },
            instance = renderdata.Sprite_Instance{
                model = renderdata.MakeSpriteModelMatrix(
                    {f32(glyph_x), f32(glyph_y)},
                    {f32(glyph.size_px[0]), f32(glyph.size_px[1])},
                    {0, 0},
                    0,
                    0,
                ),
                uv_min = glyph.uv_min,
                uv_max = glyph.uv_max,
                color = _color,
            },
        })

        // Advance the pen so the next character is positioned correctly.
        pen_x += kern + glyph.advance_x
        prev = char
    }
}

ShutdownGameplayUI :: proc(_ui : ^Clay_UI) {
    current := clay.GetCurrentContext()
    if current == _ui.clay_ctx {
        clay.SetCurrentContext(nil)
    }

    ShutdownFontAtlas(&_ui.gameplay_font)
    // Clean up clay memory arena
    if len(_ui.arena_mem) > 0 {
        delete(_ui.arena_mem)
        _ui.arena_mem = nil
    }

    _ui.clay_ctx = nil
    _ui.initialized = false
}
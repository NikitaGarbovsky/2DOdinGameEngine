package editorimgui

import imgui "Dependencies:odin-imgui"

///
/// Definitions for editorimgui objects utilized by the editorimgui
///

is_asset_browser_open : bool 
is_debug_info_open : bool

// The font data the editor uses for imgui
s_editor_font : ^imgui.Font
l_editor_font : ^imgui.Font // #TODO: fix these so you can apply them

// Contains captured input for the editor imgui
Input_Capture :: struct {
    mouse    : bool,
    keyboard : bool,
}

Editor_Debug_Info :: struct {
    framerate : f64,
    ms : f64,
    batchCount : int,
    renderedWorldElementsThisFrame : u32,
    totalRenderedElementsThisFrame : u32,
    culledEntitySpriteThisFrame : int,
    culledTilemapSpriteThisFrame : int,
}

frameDebugInfo : Editor_Debug_Info
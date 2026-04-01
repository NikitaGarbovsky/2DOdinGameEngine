package editorimgui

import imgui "Dependencies:odin-imgui"

///
/// Definitions for editorimgui objects utilized by the editorimgui
///

is_asset_browser_open: bool

// The font data the editor uses for imgui
s_editor_font : ^imgui.Font
l_editor_font : ^imgui.Font // #TODO: fix these so you can apply them

// Contains captured input for the editor imgui
Input_Capture :: struct {
    mouse    : bool,
    keyboard : bool,
}


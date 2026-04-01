package editorimgui

import imgui "Dependencies:odin-imgui"

///
/// Contains the implementation details of the full imgui editor.
///


// Draws the asset browser to the screen.
DrawAssetBrowser :: proc() {
    vp := imgui.get_main_viewport()
    if vp == nil do return

    win_size := imgui.Vec2{125, 40}
    win_pos := imgui.Vec2{
        x = vp.work_size.x - vp.work_size.x + 12.0,
        y = vp.work_pos.y + vp.work_size.y - win_size.y - 12.0,
    }

    imgui.set_next_window_pos(win_pos, .Always)
    imgui.set_next_window_size(win_size, .Always)

    flags: imgui.Window_Flags = {
        .No_Resize,
        .No_Move,
        .No_Collapse,
        .No_Saved_Settings,
        .No_Title_Bar,
        .No_Scrollbar
    }

    imgui.push_font(l_editor_font)
    if imgui.begin("Editor", nil, flags) {
        if imgui.button("Asset Browser") {
            is_asset_browser_open = !is_asset_browser_open
        }
    }
    imgui.pop_font()
    imgui.end()
}
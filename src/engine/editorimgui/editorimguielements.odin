package editorimgui

import imgui "Dependencies:odin-imgui"

///
/// Contains the implementation details of the full imgui editor.
///


// Draws the asset browser to the screen.
DrawAssetBrowser :: proc() {
    if imgui.begin("Editor") {
        if imgui.button("Asset Browser") {
            is_asset_browser_open = !is_asset_browser_open
        }
    }
    imgui.end()
}
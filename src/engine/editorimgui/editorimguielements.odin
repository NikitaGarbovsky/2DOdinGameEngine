package editorimgui

import "core:fmt"
import "core:strings"
import imgui "Dependencies:odin-imgui"
import "core:math"
import "core:os"
import "core:sort"
import "core:path/filepath"
///
/// Contains the implementation details of the full imgui editor.
///


DrawDebugInfo :: proc() {
    DrawAssetBrowserButton()
    DrawDebugButton()
    if is_debug_info_open {
        DrawDebugInfoWindow()
    }
    if is_asset_browser_open {
        DrawAssetBrowser()
    }
}

// Draws the asset browser to the screen.
DrawAssetBrowserButton :: proc() {
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
    if imgui.begin("AssetBrowserButton", nil, flags) {
        if imgui.button("Asset Browser") {
            fmt.printfln("Asset Browser Button Pressed")
            is_asset_browser_open = !is_asset_browser_open
        }
    }
    imgui.pop_font()
    imgui.end()
}

// Draws debugging information from the engine 
DrawDebugButton :: proc() {
    vp := imgui.get_main_viewport()
    if vp == nil do return

    win_size := imgui.Vec2{100, 40}
    win_pos := imgui.Vec2{
        x = vp.work_size.x - win_size.x - 12.0,
        y = win_size.y - 25,
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
    if imgui.begin("DebugWindowButton", nil, flags) {
        if imgui.button("Debug Info") {
            fmt.printfln("Debug Info Button Pressed")
            is_debug_info_open = !is_debug_info_open
        }
    }
    imgui.pop_font()
    imgui.end()
}

DrawDebugInfoWindow :: proc() {
    vp := imgui.get_main_viewport()
    if vp == nil do return

    win_size := imgui.Vec2{300, 350}
    win_pos := imgui.Vec2{
        x = vp.work_size.x - win_size.x - 12.0,
        y = vp.work_size.y - vp.work_size.y + win_size.y * 0.1 + 25,
    }

    imgui.set_next_window_pos(win_pos, .Always)
    imgui.set_next_window_size(win_size, .Always)

    flags: imgui.Window_Flags = {
        .No_Move,
        .No_Collapse,
        .No_Saved_Settings,
        .No_Scrollbar,
        .No_Resize,
    }

    if imgui.begin("Engine Debug Information", nil, flags) {

        // #TODO: BAD BAD BAD, make this system better
        framerateStr := fmt.tprint(math.round(frameDebugInfo.framerate * 1))
        strFramerate : []string = {"FPS: ", framerateStr}
        resultframerrateStr := strings.concatenate(strFramerate)
        cstrFramerate := strings.clone_to_cstring(resultframerrateStr)
        defer delete(cstrFramerate)
        imgui.text(cstrFramerate)

        if imgui.collapsing_header("Renderer") {

            imgui.text_unformatted("Per Frame")
            imgui.separator()

            msStr := fmt.tprint(math.round(frameDebugInfo.ms * 1))
            strMS : []string = {"MS: ", msStr}
            resultstrMS := strings.concatenate(strMS)
            cstrMS := strings.clone_to_cstring(resultstrMS)
            defer delete(cstrMS)
            imgui.text(cstrMS)
            
            batchCountStr := fmt.tprint(frameDebugInfo.batchCount)
            strs : []string = {"Batch Count: ", batchCountStr}
            result := strings.concatenate(strs)
            cstr := strings.clone_to_cstring(result)
            defer delete(cstr)
            imgui.text(cstr)

            renderedItems := fmt.tprint(frameDebugInfo.renderedWorldElementsThisFrame)
            strs1 : []string = {"World Rendered Item's: ", renderedItems}
            resultstr1 := strings.concatenate(strs1)
            cstr1 := strings.clone_to_cstring(resultstr1)
            defer delete(cstr1)
            imgui.text(cstr1)

            renderedItems1 := fmt.tprint(frameDebugInfo.totalRenderedElementsThisFrame)
            strs2 : []string = {"Total Rendered Item's: ", renderedItems1}
            resultstr2 := strings.concatenate(strs2)
            cstr2 := strings.clone_to_cstring(resultstr2)
            defer delete(cstr2)
            imgui.text(cstr2)

            culledItems0 := fmt.tprint(frameDebugInfo.culledEntitySpriteThisFrame)
            strCulled0 : []string = {"Culled Entities: ", culledItems0}
            resultStrCulled0 := strings.concatenate(strCulled0)
            cstrCulled := strings.clone_to_cstring(resultStrCulled0)
            defer delete(cstrCulled)
            imgui.text(cstrCulled)

            culledItems1 := fmt.tprint(frameDebugInfo.culledTilemapSpriteThisFrame)
            strCulled1 : []string = {"Culled Tile's: ", culledItems1}
            resultStrCulled1 := strings.concatenate(strCulled1)
            cstrCulled0 := strings.clone_to_cstring(resultStrCulled1)
            defer delete(cstrCulled0)
            imgui.text(cstrCulled0)
        }
    }

    imgui.end()
}

DrawAssetBrowser :: proc() {
    vp := imgui.get_main_viewport()
    if vp == nil do return


    flags : imgui.Window_Flags = {
            .No_Collapse,
            .No_Saved_Settings,
            .No_Resize,
        }

    win_size := imgui.Vec2{vp.work_size.x / 3, 450}
    win_pos := imgui.Vec2{
        x = vp.work_size.x - vp.work_size.x + 12.0,
        y = vp.work_pos.y + vp.work_size.y - win_size.y - 50,
    }

    imgui.set_next_window_pos({win_pos.x, win_pos.y}, imgui.Cond.Always)
    imgui.set_next_window_size(win_size, imgui.Cond.Always)
    imgui.begin("Asset Browser Window", &is_asset_browser_open, flags)

    imgui.set_next_item_width(240.0)
    // imgui.input_text_with_hint("##search", "Search...", AssetSearchArr, imgui.)
    // imgui.separator()

    leftW : f32 = 280.0

    imgui.begin_child("##dir_tree", imgui.Vec2{leftW, 0})

    // Check if asset root path is valid.
    if !os.exists(asset_root_path) {
        fmt.printfln("{} Root path for asset browser does not exist", asset_root_path)
    }
    else  {
        // Set tree node flags
        rootFlags : imgui.Tree_Node_Flags = {
            .Default_Open,
            .Open_On_Arrow,
            .Span_Full_Width,
        }

        if current_asset_browser_directory == asset_root_path {
            rootFlags |= { .Selected }
        }

        rootOpen : bool = imgui.tree_node_ex("Assets", rootFlags)

        if rootOpen {
            DrawCachedNodeRecursive(&asset_tree_root)
            imgui.tree_pop()
        }
    }

    imgui.end_child()

    imgui.same_line()

    imgui.begin_child("##items", imgui.Vec2{0, 0})
    // #TODO: Create the side panel containing the files here.

    imgui.end_child()
    imgui.end()

}

// Helper for getting the child directories when filling the Asset Browser
GatherChildDirs :: proc(_root : string, _outKids : ^[dynamic]string) {
    clear(_outKids)

    if !os.is_dir(_root) do return 

    handle, err := os.open(_root)
    if err != os.ERROR_NONE do return
    defer os.close(handle)

    infos, read_err := os.read_dir(handle, -1, context.allocator)
    if read_err != os.ERROR_NONE do return
    defer delete(infos)

    for info in infos {
        full_path, err := filepath.join({_root, info.name}, context.temp_allocator)
        append(_outKids, strings.clone(full_path))
    }

    sort.quick_sort(_outKids^[:])
}

// Used by asset browser to draw the cached directories from the Resources folder 
DrawCachedNodeRecursive :: proc(node: ^Asset_Node) {
    flags: imgui.Tree_Node_Flags = { .Open_On_Arrow, .Span_Full_Width }
    
    if !node.is_directory do flags |= { .Leaf }
    if current_asset_browser_directory == node.full_path do flags |= { .Selected }

    c_name := strings.clone_to_cstring(node.name, context.temp_allocator)
    
    // Check if it was open last frame to keep state
    if node.is_expanded do imgui.set_next_item_open(true)

    open := imgui.tree_node_ex(c_name, flags)
    
    if imgui.is_item_clicked() {
        current_asset_browser_directory = node.full_path
    }

    if open {
        node.is_expanded = true
        for child in node.children {
            DrawCachedNodeRecursive(child)
        }
        imgui.tree_pop()
    } else {
        node.is_expanded = false
    }
}

// Scanns the passed directory and caches all the child files & folders
// mainly used by the asset browser 
ScanDirectory :: proc(_path: string) -> ^Asset_Node {

    // Creates a new node and fills its data
    node := new(Asset_Node)
    node.full_path = strings.clone(_path)
    node.name = strings.clone(filepath.base(_path))
    node.is_directory = os.is_dir(_path)

    if node.is_directory {
        handle, err := os.open(_path)
        if err == os.ERROR_NONE {
            defer os.close(handle)
            infos, _ := os.read_dir(handle, -1, context.allocator)
            
            // Loop through all the found children in this directory and 
            // recursively scan again. 
            for info in infos {
                child_path, err := filepath.join({_path, info.name}, context.allocator)
                append(&node.children, ScanDirectory(child_path))
                delete(child_path) 
            }
        }
    }
    return node
}
package tilemap

import "core:log"
import "../renderdata"
import imgui "Dependencies:odin-imgui"
import "core:strings"

///
/// Manages the editing functionality of the tilemap. Mainly declars dear_imgui elements.
///


// Object containing editor tilemap input state
Tilemap_Editor_Input :: struct {
    mouse_screen_pos : [2]f32, // Mouse screen space position
    mouse_delta : [2]f32, // Mouse movement difference
    mouse_scroll_up : f32, // Zoom in
    mouse_scroll_down : f32, // Zoom out

    left_clicked : bool, // Tile paint
    right_down : bool, // Hold to move

    delete_pressed : bool, // Toggle tile delete mode
    space_down : bool, // Hold with right click to move

    imgui_mouse_captured : bool, // Imgui mouse over
    imgui_keyboard_captured : bool, // Imgui keyboard input
}


// Sets the specific tile based of ID to paint onto the tilemap
SelectTileForPainting :: proc(_level : ^Level_State, _def_id : Tile_Def_ID) {
    _level.editor.selected_tile = _def_id
    _level.editor.has_selected_tile = true
    _level.editor.mode = .Paint

    // Forces a resync to occur to the saved file that holds the origin 
    _level.editor.origin_edit_loaded = false
    _level.editor.origin_edit_loaded_for = Tile_Def_ID(0)
}

PaletteGroupLabel :: proc(_group : Tile_Palette_Group) -> cstring {
    switch _group {
    case .Ground:  return "Ground"
    case .Walls:   return "Walls"
    case .Props:   return "Props"
    case .Details: return "Details"
    }
    return "Unknown"
}

SyncSelectedTileOriginEditor :: proc(_level : ^Level_State) {
    if !_level.editor.has_selected_tile do return

    if !_level.editor.origin_edit_loaded || _level.editor.origin_edit_loaded_for != _level.editor.selected_tile {
        def, ok := GetTileDef(&_level.defsLibrary, _level.editor.selected_tile)
        if !ok do return

        _level.editor.origin_edit_value = def.origin
        _level.editor.origin_edit_loaded = true
        _level.editor.origin_edit_loaded_for = _level.editor.selected_tile
    }
}

CommitSelectedTileOrigin :: proc(_level : ^Level_State, _origin : [2]f32) {
    if !_level.editor.has_selected_tile do return

    def, ok := GetTileDef(&_level.defsLibrary, _level.editor.selected_tile)
    if !ok do return

    def.origin = _origin
    _level.editor.origin_edit_value = _origin
}

DrawEditorUI :: proc(_level : ^Level_State) {
    if !_level.editor.enabled do return

    DrawEditorToolbar(_level)
    DrawTilePaletteWindow(_level)
    DrawLevelText(_level)
}

DrawLayerButton :: proc(_level : ^Level_State, _layer : Tilemap_Layer) {
    selected := _level.editor.selected_layer == _layer

    if selected {
        imgui.push_style_color_vec4(.Button,         imgui.Vec4{0.35, 0.30, 0.50, 1.0})
        imgui.push_style_color_vec4(.Button_Hovered, imgui.Vec4{0.45, 0.40, 0.60, 1.0})
        imgui.push_style_color_vec4(.Button_Active,  imgui.Vec4{0.30, 0.25, 0.45, 1.0})
    }

    if imgui.button(TilemapLayerLabel(_layer)) {
        _level.editor.selected_layer = _layer
    }

    if selected {
        imgui.pop_style_color(3)
    }
}

DrawLevelText :: proc(_level : ^Level_State) {
    vp := imgui.get_main_viewport()
    if vp == nil do return

    win_size := imgui.Vec2{180, 36}
    win_pos := imgui.Vec2{
        x = vp.work_pos.x + (vp.work_size.x * 0.5) - (win_size.x * 0.5),
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
    }

    if imgui.begin("##LevelToolbar", nil, flags) {
        if _level.editor.current_level_path.len <= 0 {
            imgui.text("No level loaded.") 
            imgui.same_line()
        }
        else {
            imgui.text("Level:") 
            imgui.same_line()
            path := string(_level.editor.current_level_path.buf[:])
            parts := strings.split(path, "\\")
            levelname := parts[len(parts) -1]
            converted_cstr := strings.clone_to_cstring(levelname) // #TODO: VERY BAD, ALLOCATING MEMORY EVERY FRAME
            defer delete(converted_cstr)
            imgui.text(converted_cstr)
        }

    }
    imgui.end()
}
DrawEditorToolbar :: proc(_level : ^Level_State) {
    vp := imgui.get_main_viewport()
    if vp == nil do return

    win_size := imgui.Vec2{285, 40}
    win_pos := imgui.Vec2{
        x = vp.work_pos.x + vp.work_size.x - win_size.x - 12.0,
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
    }

    if imgui.begin("##TilemapToolbar", nil, flags) {
        if imgui.button("Save Level") {
            _ = SaveCurrentLevelOrPromptSaveAs(_level)
        }
        imgui.same_line()
        if imgui.button("Load Level") {
            RequestOpenLevelDialog(_level)
        }
        
        imgui.same_line()
        palette_button_selected := _level.editor.palette_open
        if palette_button_selected {
            imgui.push_style_color_vec4(.Button,         imgui.Vec4{0.35, 0.30, 0.50, 1.0})
            imgui.push_style_color_vec4(.Button_Hovered, imgui.Vec4{0.45, 0.40, 0.60, 1.0})
            imgui.push_style_color_vec4(.Button_Active,  imgui.Vec4{0.30, 0.25, 0.45, 1.0})
        }

        if imgui.button("Tile Palette") {
            _level.editor.palette_open = !_level.editor.palette_open
        }

        if palette_button_selected {
            imgui.pop_style_color(3)
        }
    }
    imgui.end()
}

DrawSelectedTileInspector :: proc(_level : ^Level_State) {
    imgui.separator()
    imgui.text_unformatted("Selected Tile:")

    if !_level.editor.has_selected_tile {
        imgui.text_unformatted("No tile selected.")
        return
    }

    def, ok := GetTileDef(&_level.defsLibrary, _level.editor.selected_tile)
    if !ok {
        imgui.text_unformatted("Selected tile missing.")
        return
    }

    SyncSelectedTileOriginEditor(_level)

    imgui.text("%.*s", len(def.key), raw_data(def.key))

    imgui.push_item_width(-1)

    changed := false

    // Slider like drag control
    imgui.text_unformatted("Origin Slider")
    if imgui.drag_float2(
        "##OriginDrag",
        &_level.editor.origin_edit_value,
        0.01,
        -1.0,
        1.0,
        "%.2f",
    ) {
        changed = true
    }

    // Exact manual entry
    imgui.text_unformatted("Origin Input")
    if imgui.input_float2(
        "##OriginInput",
        &_level.editor.origin_edit_value,
        "%.3f",
    ) {
        changed = true
    }

    imgui.pop_item_width()

    if changed {
        CommitSelectedTileOrigin(_level, _level.editor.origin_edit_value)
        SaveTileOriginOverrides(_level)
    }
}

DrawTilePaletteWindow :: proc(_level : ^Level_State) {
    if !_level.editor.palette_open do return

    vp := imgui.get_main_viewport()
    if vp == nil do return

    win_size := imgui.Vec2{
        _level.editor.palette_window_size[0],
        _level.editor.palette_window_size[1],
    }

    win_pos := imgui.Vec2{
        x = vp.work_pos.x + vp.work_size.x - win_size.x - 12.0,
        y = vp.work_pos.y + vp.work_size.y - win_size.y - 56.0,
    }

    imgui.set_next_window_pos(win_pos, .Always)
    imgui.set_next_window_size(win_size, .Always)

    open := _level.editor.palette_open

    flags: imgui.Window_Flags = {
        .No_Resize,
        .No_Saved_Settings,
    }

    if imgui.begin("Tile Palette", &open, flags) {
        _level.editor.palette_open = open

        imgui.separator()
        imgui.text_unformatted("Active Layer:")
        imgui.same_line()
        DrawLayerButton(_level, .Ground)
        imgui.same_line()
        DrawLayerButton(_level, .Walls)
        imgui.same_line()
        DrawLayerButton(_level, .Decoration)

        imgui.begin_child("##palette_tiles", imgui.Vec2{win_size.x - 200.0, 0.0}, {.Borders}, {})
        DrawTilePaletteGrid(_level)
        imgui.end_child()

        imgui.same_line()

        imgui.begin_child("##palette_groups", imgui.Vec2{0.0, 0.0}, {.Borders}, {})
        DrawPaletteGroupButtons(_level)
        DrawSelectedTileInspector(_level)
        imgui.end_child()
    } else {
        _level.editor.palette_open = open
    }

    imgui.end()
}

DrawPaletteGroupButtons :: proc(_level : ^Level_State) {
    groups := []Tile_Palette_Group{.Ground, .Walls, .Props, .Details}

    for i := 0; i < len(groups); i += 1 {
        group := groups[i]
        selected := _level.editor.selected_group == group

        if selected {
            imgui.push_style_color_vec4(.Button,         imgui.Vec4{0.35, 0.30, 0.50, 1.0})
            imgui.push_style_color_vec4(.Button_Hovered, imgui.Vec4{0.45, 0.40, 0.60, 1.0})
            imgui.push_style_color_vec4(.Button_Active,  imgui.Vec4{0.30, 0.25, 0.45, 1.0})
        }

        if imgui.button(PaletteGroupLabel(group)) {
            _level.editor.selected_group = group
        }

        if selected {
            imgui.pop_style_color(3)
        }
    }
}

DrawTilePaletteGrid :: proc(_level : ^Level_State) {
    thumb_size := _level.editor.palette_thumb_size
    spacing: f32 = 8.0

    avail := imgui.get_content_region_avail()
    
    cols := int((avail.x + spacing) / (thumb_size + spacing))
    if _level.editor.selected_group != .Ground {cols = 5} // lazy af solution but it works!
    if cols < 1 do cols = 1

    visible_index := 0

    for i := 0; i < len(_level.editor.palette_items); i += 1 {
        item := _level.editor.palette_items[i]
        if item.group != _level.editor.selected_group do continue

        def, ok := GetTileDef(&_level.defsLibrary, item.def_id)
        if !ok do continue

        if visible_index > 0 && visible_index % cols != 0 {
            imgui.same_line()
        }

        DrawPaletteTileButton(_level, item, def)
        visible_index += 1
    }

    if visible_index == 0 {
        imgui.text_unformatted("No tiles in this group yet.")
    }
}

DrawPaletteTileButton :: proc(
    _level : ^Level_State,
    _item  : Palette_Item,
    _def   : ^Tile_Definition,
) {
    if _level.editor.palette_texture_imgui_id == nil do return

    tex_id := imgui.Texture_ID(uintptr(_level.editor.palette_texture_imgui_id))

    draw_w := _item.preview_px[0]
    draw_h := _item.preview_px[1]

    max_dim := draw_w
    if draw_h > max_dim do max_dim = draw_h

    if max_dim > _level.editor.palette_thumb_size && max_dim > 0 {
        scale := _level.editor.palette_thumb_size / max_dim
        draw_w *= scale
        draw_h *= scale
    }

    uv0 := imgui.Vec2{_def.uv_min[0], _def.uv_min[1]}
    uv1 := imgui.Vec2{_def.uv_max[0], _def.uv_max[1]}

    selected := _level.editor.has_selected_tile && _level.editor.selected_tile == _item.def_id

    if selected {
        imgui.push_style_color_vec4(.Button,         imgui.Vec4{0.35, 0.30, 0.50, 1.0})
        imgui.push_style_color_vec4(.Button_Hovered, imgui.Vec4{0.45, 0.40, 0.60, 1.0})
        imgui.push_style_color_vec4(.Button_Active,  imgui.Vec4{0.30, 0.25, 0.45, 1.0})
    }

    imgui.push_id_int(i32(u32(_item.def_id)))
    clicked := imgui.image_button(
        "##palette_tile",
        tex_id,
        imgui.Vec2{draw_w, draw_h},
        uv0,
        uv1,
        imgui.Vec4{0, 0, 0, 0},
        imgui.Vec4{1, 1, 1, 1},
    )
    imgui.pop_id()

    if selected {
        imgui.pop_style_color(3)
    }

    if clicked {
        SelectTileForPainting(_level, _item.def_id)
    }

    if imgui.is_item_hovered() {
        if imgui.begin_tooltip() {
            imgui.text("%.*s", len(_item.label), raw_data(_item.label))
            imgui.end_tooltip()
        }
    }
}

// Utilizes user input to update & execute editor functionality
UpdateEditorBasedOnInput :: proc(
    _level : ^Level_State,
    _cam : ^renderdata.Camera2D,
    _input : Tilemap_Editor_Input,
) {
    if !_level.editor.enabled {
        _level.editor.has_hovered_cell = false
        return
    }

    // Enable delete tile mode 
    if !_input.imgui_keyboard_captured && _input.delete_pressed {
        if _level.editor.mode == .Delete {
            _level.editor.mode = .Paint
        } else {
            _level.editor.mode = .Delete
        }
    }

    // Updates camera positioning
    if UpdateEditorCameraPan(_cam, _input) {
        _level.editor.has_hovered_cell = false
        return
    }

    // Don't display the tile hover ghost if ui has input captured 
    if _input.imgui_mouse_captured {
        _level.editor.has_hovered_cell = false
        return
    }

    // Conversions 
    world_pos := renderdata.ScreenToWorldPos(_cam, _input.mouse_screen_pos)
    hovered := WorldToIsoGridCoordinate(world_pos, _level.resources.tile_w, _level.resources.tile_h)

    // Apply hovered tile positioning
    _level.editor.hovered_cell = hovered
    _level.editor.has_hovered_cell = true

    active_tmap := GetTilemapForLayer(_level, _level.editor.selected_layer)
    
    // Place or Delete the tile on the tilemap 
    if _input.left_clicked {
        switch _level.editor.mode {
        case .Paint:
            if _level.editor.has_selected_tile {
                PlaceTile(active_tmap, hovered, _level.editor.selected_tile)
            }

        case .Delete:
            RemoveTile(active_tmap, hovered)
        }
    }

    if _input.mouse_scroll_up > 0{
        renderdata.CameraZoomIn(_cam, _input.mouse_scroll_up)
        //log.debug("Zoom In: ", _cam.zoom)
    }

    if _input.mouse_scroll_down < 0{
        renderdata.CameraZoomOut(_cam, _input.mouse_scroll_down)
        //log.debug("Zoom Out: ", _cam.zoom)
    } 
}

// Updates the editor camera position based off user input per update loop. 
UpdateEditorCameraPan :: proc(
    _cam : ^renderdata.Camera2D,
    _input : Tilemap_Editor_Input,
) -> bool {
    // No input detected? Don't do anything
    if !_input.space_down do return false
    if !_input.right_down do return false
    if _input.imgui_mouse_captured do return false

    // No mouse movement detected, no need to update further
    if _input.mouse_delta[0] == 0 && _input.mouse_delta[1] == 0 {
        return true
    }
    // ============ Input detected ============

    // Calculate the previous mouse position
    prev_mouse := [2]f32{
        _input.mouse_screen_pos[0] - _input.mouse_delta[0],
        _input.mouse_screen_pos[1] - _input.mouse_delta[1],
    }

    // Conversion
    world_prev := renderdata.ScreenToWorldPos(_cam, prev_mouse)
    world_curr := renderdata.ScreenToWorldPos(_cam, _input.mouse_screen_pos)

    // Delta (mouse movement difference)
    delta := [2]f32{
        world_prev[0] - world_curr[0],
        world_prev[1] - world_curr[1],
    }

    // Update camera position 
    _cam.position[0] += delta[0]
    _cam.position[1] += delta[1]

    return true
}
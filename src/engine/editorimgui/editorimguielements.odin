package editorimgui

import "core:fmt"
import "core:strings"
import imgui "Dependencies:odin-imgui"
import "core:math"
import "core:os"
import "core:sort"
import "core:path/filepath"
import "../ecs"
import "../components"

///
/// Contains the implementation details of the full imgui editor, each procedure represents a 
/// drawable element for dear_imgui. 
///


// Draws all the collective elements
DrawDebugInfo :: proc(_world : ^ecs.EntityWorld) {
    DrawEntitiesButton()
    DrawAssetBrowserButton()
    DrawDebugButton()

    if is_entities_open {
        DrawEntitiesWindow(_world)
    }
    if is_debug_info_open {
        DrawDebugInfoWindow()
    }
    if is_asset_browser_open {
        DrawAssetBrowser()
    }
}


// Draws the asset browser to the screen.
@private
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
@private
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

// The debug window that is displayed from the debug button
// #TODO: this has some terrible allocation issues that I will fix at some stage 
@private
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

// The asset browser displaying file structure
@private
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
@private
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
@private
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
@private
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

// The entity button at the top left-hand side of the screen.
@private
DrawEntitiesButton :: proc() {
    vp := imgui.get_main_viewport()
    if vp == nil do return

    win_size := imgui.Vec2{76, 40}
    win_pos := imgui.Vec2{
        x = vp.work_pos.x + 12.0,
        y = vp.work_pos.y + 12.0,
    }

    imgui.set_next_window_pos(win_pos, .Always)
    imgui.set_next_window_size(win_size, .Always)

    flags : imgui.Window_Flags = {
        .No_Resize,
        .No_Move,
        .No_Collapse,
        .No_Saved_Settings,
        .No_Title_Bar,
        .No_Scrollbar,
    }

    imgui.push_font(l_editor_font)
    if imgui.begin("EntitiesButtonWindow", nil, flags) {
        if imgui.button("Entities") {
            is_entities_open = !is_entities_open
        }
    }
    imgui.pop_font()
    imgui.end()
}

// Sorts all the alive entities by ID for the entity dropdown list
@private
GetAliveEntitiesSorted :: proc(_world : ^ecs.EntityWorld, _out : ^[dynamic]ecs.Entity) {
    clear(_out)

    for entity, alive in _world.alive {
        if alive {
            append(_out, entity)
        }
    }

    sort.quick_sort_proc(_out[:], proc(a, b: ecs.Entity) -> int {
        if a.id < b.id do return -1
        if a.id > b.id do return 1
        return 0
    })
}

// Helper, returns the entity name from the name component attached to it.
@private
GetEntityDisplayName :: proc(_world : ^ecs.EntityWorld, _entity : ecs.Entity) -> string {
    if name, ok := ecs.GetComponent(&_world.names, _entity); ok {
        return fmt.tprintf("[%d] %s", _entity.id, name.entityName)
    }
    return fmt.tprintf("[%d] <Unnamed>", _entity.id)
}

// Draws the entity window containing all the mutatable entity information.
@private
DrawEntitiesWindow :: proc(_world : ^ecs.EntityWorld) {
    vp := imgui.get_main_viewport()
    if vp == nil do return

    win_size := imgui.Vec2{420, 600}
    win_pos := imgui.Vec2{
        x = vp.work_pos.x + 12.0,
        y = vp.work_pos.y + 60.0,
    }

    flags : imgui.Window_Flags = {
        .No_Collapse,
        .No_Saved_Settings,
    }

    imgui.set_next_window_pos(win_pos, .Always)
    imgui.set_next_window_size(win_size, .Always)

    if imgui.begin("Entities", &is_entities_open, flags) {
        if imgui.button("Spawn Minecart") {
            editor_actions.spawn_minecart = true
        }
        imgui.same_line()
        if imgui.button("Spawn Gold Ingot") {
            editor_actions.spawn_gold_ingot = true
        }

        imgui.separator()

        entities : [dynamic]ecs.Entity
        defer delete(entities)
        GetAliveEntitiesSorted(_world, &entities)

        // If selected entity got deleted, clear selection #TODO: Currently no entity deletion in the editor
        if entity_inspector_state.has_selected_entity {
            if _, ok := _world.alive[entity_inspector_state.selected_entity]; !ok {
                entity_inspector_state.has_selected_entity = false
            }
        }

        preview_text := "None"
        if entity_inspector_state.has_selected_entity {
            preview_text = GetEntityDisplayName(_world, entity_inspector_state.selected_entity)
        }

        preview_c := strings.clone_to_cstring(preview_text, context.temp_allocator)

        if imgui.begin_combo("Selected Entity", preview_c) {
            for entity in entities {
                label := GetEntityDisplayName(_world, entity)
                label_c := strings.clone_to_cstring(label, context.temp_allocator)

                is_selected := entity_inspector_state.has_selected_entity &&
                               entity.id == entity_inspector_state.selected_entity.id

                if imgui.selectable(label_c, is_selected) {
                    entity_inspector_state.selected_entity = entity
                    entity_inspector_state.has_selected_entity = true
                }

                if is_selected {
                    imgui.set_item_default_focus()
                }
            }
            imgui.end_combo()
        }

        imgui.separator()

        if entity_inspector_state.has_selected_entity {
            DrawSelectedEntityInspector(_world, entity_inspector_state.selected_entity)
        } else {
            imgui.text_unformatted("No entity selected.")
        }
    }

    imgui.end()
}

// Draws all the component fields that are attached to the entity.
@private
DrawSelectedEntityInspector :: proc(_world : ^ecs.EntityWorld, _entity : ecs.Entity) {
    label := GetEntityDisplayName(_world, _entity)
    label_c := strings.clone_to_cstring(label, context.temp_allocator)
    imgui.text(label_c)
    imgui.separator()

    if name, ok := ecs.GetComponent(&_world.names, _entity); ok {
        if imgui.collapsing_header("Name") {
            name_c := strings.clone_to_cstring(name.entityName, context.temp_allocator)
            imgui.text(name_c)
        }
    }

    if transform, ok := ecs.GetComponent(&_world.transforms, _entity); ok {
        if imgui.collapsing_header("Transform") {
            pos := [2]f32{transform.pos.x, transform.pos.y}
            if imgui.drag_float2("Position", &pos, 1.0) {
                transform.pos = {pos[0], pos[1]}
            }

            rot := transform.rot
            if imgui.drag_float("Rotation", &rot, 0.01) {
                transform.rot = rot
            }
        }
    }

    if sprite, ok := ecs.GetComponent(&_world.sprites, _entity); ok {
        if imgui.collapsing_header("Sprite") {
            size := [2]f32{sprite.size.x, sprite.size.y}
            if imgui.drag_float2("Size", &size, 0.1) {
                sprite.size = {size[0], size[1]}
            }

            if imgui.drag_float2("UV Min", &sprite.uv_min, 0.001) {}
            if imgui.drag_float2("UV Max", &sprite.uv_max, 0.001) {}
            if imgui.drag_float2("Origin", &sprite.origin, 0.01) {}
            if imgui.color_edit4("Color", &sprite.color) {}

            layer := sprite.layer
            if imgui.input_int("Layer", &layer) {
                sprite.layer = layer
            }
        }
    }

    if collider, ok := ecs.GetComponent(&_world.colliders, _entity); ok {
        if imgui.collapsing_header("Collider") {
            imgui.text_unformatted("Shape")
            if imgui.small_button("Box") {
                collider.shape = .Box
            }
            imgui.same_line()
            if imgui.small_button("Circle") {
                collider.shape = .Circle
            }

            switch collider.shape {
            case .Box:
                half := [2]f32{collider.half_extends.x, collider.half_extends.y}
                if imgui.drag_float2("Half Extents", &half, 0.1) {
                    collider.half_extends = {half[0], half[1]}
                }
            case .Circle:
                radius := collider.radius
                if imgui.drag_float("Radius", &radius, 0.1) {
                    collider.radius = radius
                }
            }

            imgui.checkbox("Is Trigger", &collider.is_trigger)
        }
    }

    if rb, ok := ecs.GetComponent(&_world.rigid_bodies, _entity); ok {
        if imgui.collapsing_header("Rigid Body") {
            imgui.text_unformatted("Body Type")
            if imgui.small_button("Static") {
                rb.body_type = .Static
            }
            imgui.same_line()
            if imgui.small_button("Dynamic") {
                rb.body_type = .Dynamic
            }
            imgui.same_line()
            if imgui.small_button("Kinematic") {
                rb.body_type = .Kinematic
            }

            imgui.checkbox("Fixed Rotation", &rb.fixed_rotation)

            linear_damping := rb.linear_damping
            if imgui.drag_float("Linear Damping", &linear_damping, 0.1) {
                rb.linear_damping = linear_damping
            }

            gravity_scale := rb.gravity_scale
            if imgui.drag_float("Gravity Scale", &gravity_scale, 0.1) {
                rb.gravity_scale = gravity_scale
            }
        }
    }

    if interactable, ok := ecs.GetComponent(&_world.interactables, _entity); ok {
        if imgui.collapsing_header("Interactable") {
            prompt_c := strings.clone_to_cstring(interactable.prompt_text, context.temp_allocator)
            imgui.text(prompt_c)

            radius := interactable.interaction_radius
            if imgui.drag_float("Interaction Radius", &radius, 0.1) {
                interactable.interaction_radius = radius
            }

            popup_offset_y := interactable.popup_offset_y
            if imgui.drag_float("Popup Offset Y", &popup_offset_y, 0.1) {
                interactable.popup_offset_y = popup_offset_y
            }

            imgui.checkbox("Enabled", &interactable.enabled)
        }
    }

    if script, ok := ecs.GetComponent(&_world.scripts, _entity); ok {
        if imgui.collapsing_header("Script") {
            path_c := strings.clone_to_cstring(script.path, context.temp_allocator)
            imgui.text(path_c)

            imgui.checkbox("Enabled", &script.enabled)
            imgui.checkbox("Hot Reload", &script.hot_reload)
        }
    }

    if inventory, ok := ecs.GetComponent(&_world.inventory, _entity); ok {
        if imgui.collapsing_header("Inventory") {
            gold := inventory.gold
            if imgui.input_int("Gold", &gold) {
                inventory.gold = gold
            }

            capacity := inventory.capacity
            if imgui.input_int("Capacity", &capacity) {
                inventory.capacity = capacity
            }
        }
    }

    if animator, ok := ecs.GetComponent(&_world.animators, _entity); ok {
        if imgui.collapsing_header("Animator") {
            req_c := strings.clone_to_cstring(animator.requested_state, context.temp_allocator)
            cur_c := strings.clone_to_cstring(animator.current_state, context.temp_allocator)

            imgui.text(req_c)
            imgui.text(cur_c)

            speed := animator.anim_player.speed
            if imgui.drag_float("Speed", &speed, 0.01) {
                animator.anim_player.speed = speed
            }

            frame_time := animator.anim_player.per_frame_time
            if imgui.drag_float("Per Frame Time", &frame_time, 0.001) {
                animator.anim_player.per_frame_time = frame_time
            }

            imgui.checkbox("Playing", &animator.anim_player.playing)
            imgui.checkbox("Flip X", &animator.anim_player.flip_x)
        }
    }
}
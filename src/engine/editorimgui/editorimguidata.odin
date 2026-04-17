package editorimgui

import imgui "Dependencies:odin-imgui"
import "../ecs"
import "../components"

///
/// Definitions for editorimgui objects utilized by the editorimgui
///

is_asset_browser_open : bool 
is_debug_info_open : bool
is_entities_open : bool

asset_root_path : string = "Resources"
current_asset_browser_directory := asset_root_path

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

// Represents any kind of asset for the asset browser
Asset_Node :: struct {
    name : string, 
    full_path : string, 
    is_directory : bool,
    is_expanded : bool,
    children : [dynamic]^Asset_Node,
}

asset_tree_root : Asset_Node

// Used to easily dictate state of immediate mode interactions with the editor
Editor_Actions :: struct {
    spawn_minecart : bool,
    spawn_gold_ingot : bool,

    delete_entity : bool,
    delete_entity_target : ecs.Entity,

    remove_component : bool,
    remove_component_target : ecs.Entity,
    remove_component_kind : components.Component_Flag,
}

editor_actions : Editor_Actions

// Used by the dropdown list for selection of entities
Entity_Inspector_State :: struct {
    selected_entity : ecs.Entity,
    has_selected_entity : bool,
}

entity_inspector_state : Entity_Inspector_State
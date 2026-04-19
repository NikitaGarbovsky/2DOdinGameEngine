#+vet explicit-allocators
package tilemap

import "../renderdata"
import glm "core:math/linalg/glsl"
import math "core:math"

/// 
/// Manages tilemap editor overlay extraction (grid, hover ghost, delete outline) 
/// as Render_Items for the rendering pipeline
///


// Extracts all tilemap editor overlay visuals (grid outline, hover ghost, delete outline)
// as render items for the render pipeline.
ExtractTilemapGridOverlay :: proc(
    _level: ^Level_State,
    _cam: ^renderdata.Camera2D,
    _out_items: ^[dynamic]renderdata.Render_Item,
) {
    if !_level.editor.enabled do return

    if _level.editor.show_grid {
        bounds := GetVisibleIsoCellBounds(
            _cam,
            _level.resources.tile_w,
            _level.resources.tile_h,
            2,
        )

        for y := bounds.min_y; y <= bounds.max_y; y += 1 {
            for x := bounds.min_x; x <= bounds.max_x; x += 1 {
                AppendIsoCellOutlineItems(
                    Tile_Coord{x = x, y = y},
                    _level.resources.tile_w,
                    _level.resources.tile_h,
                    _level.editor.grid_thickness,
                    _level.editor.grid_sort_layer,
                    _level.editor.grid_color,
                    _out_items,
                )
            }
        }
    }

    if _level.editor.has_hovered_cell {
        hover_color := _level.editor.hover_color

        if _level.editor.mode == .Delete {
            hover_color = _level.editor.hover_delete_color
        }

        AppendIsoCellOutlineItems(
            _level.editor.hovered_cell,
            _level.resources.tile_w,
            _level.resources.tile_h,
            _level.editor.grid_thickness * 2.0,
            _level.editor.grid_sort_layer + 1,
            hover_color,
            _out_items,
        )
    }

    AppendHoverPreviewItem(_level, _level.editor.grid_sort_layer + 2, _out_items)
}

Visible_Cell_Bounds :: struct {
    min_x: i32,
    max_x: i32,
    min_y: i32,
    max_y: i32,
}

// Computes the min/max isometric grid cell range that may be visible inside the camera world rect.
@private
GetVisibleIsoCellBounds :: proc(
    _cam: ^renderdata.Camera2D,
    _tile_w, _tile_h: f32,
    _padding: i32,
) -> Visible_Cell_Bounds {
    // 1. Get the camera’s world-space visible rect
    rect := renderdata.CameraWorldRect(_cam)

    // 2. Take the 4 world-space corners of rect
    corners := [4][2]f32{
        {rect.min[0], rect.min[1]},
        {rect.max[0], rect.min[1]},
        {rect.min[0], rect.max[1]},
        {rect.max[0], rect.max[1]},
    }

    // Prepare min/max trackers, infinity values to gurantee overwrite
    min_gx := f32( 1e30)
    max_gx := f32(-1e30)
    min_gy := f32( 1e30)
    max_gy := f32(-1e30)

    for c in corners {
        // 3. Convert each corner from world space into floating-point iso grid coordinates
        gridCoor := WorldToIsoGridFloat(c, _tile_w, _tile_h)

        // 4. Find min/max grid extents across 4 converted corners
        if gridCoor[0] < min_gx do min_gx = gridCoor[0]
        if gridCoor[0] > max_gx do max_gx = gridCoor[0]
        if gridCoor[1] < min_gy do min_gy = gridCoor[1]
        if gridCoor[1] > max_gy do max_gy = gridCoor[1]
    }

    return Visible_Cell_Bounds{
        // 5. Floor/ceil the values to integer cell bounds
        // 6. Expand by padding
        min_x = i32(math.floor(min_gx)) - _padding,
        max_x = i32(math.ceil(max_gx)) + _padding,
        min_y = i32(math.floor(min_gy)) - _padding,
        max_y = i32(math.ceil(max_gy)) + _padding,
    }
}

// Appends a line-shaped render item used for tilemap editor overlays. (grid)
@private
AppendLineItem :: proc(
    _center: [2]f32,
    _length: f32,
    _thickness: f32,
    _rotation: f32,
    _sort_layer: i32,
    _color: [4]f32,
    _out_items: ^[dynamic]renderdata.Render_Item,
) {
    item := renderdata.Render_Item{
        pass = .Debug,
        sort_layer = _sort_layer,
        y_sort = _center[1],

        material = renderdata.Material_Key{
            pipeline = .Sprite,
            texture  = renderdata.Default_Texture_Handle,
            sampler  = renderdata.Default_Sampler_Handle,
            blend    = .Alpha,
        },

        instance = renderdata.Sprite_Instance{
            model = renderdata.MakeSpriteModelMatrix(
                _center,
                {_length, _thickness},
                {0.5, 0.5},
                _rotation,
                0,
            ),
            uv_min = {0, 0},
            uv_max = {1, 1},
            color  = _color,
        },
    }

    append(_out_items, item)
}

// Creates the 4 lines that form one isometric cell outline(grid) and appends it
// as a Render_Item
@private
AppendIsoCellOutlineItems :: proc(
    _cell: Tile_Coord,
    _tile_w, _tile_h: f32,
    _thickness: f32,
    _sort_layer: i32,
    _color: [4]f32,
    _out_items: ^[dynamic]renderdata.Render_Item,
) {
    center := IsoGridCoordinateToWorldPos(_cell, _tile_w, _tile_h)

    half_w := _tile_w * 0.5
    half_h := _tile_h * 0.5

    edge_len := f32(math.sqrt(f64(half_w * half_w + half_h * half_h)))
    angle := f32(math.atan2(f64(half_h), f64(half_w)))

    offsets := [4][2]f32{
        { half_w * 0.5, -half_h * 0.5},
        { half_w * 0.5,  half_h * 0.5},
        {-half_w * 0.5,  half_h * 0.5},
        {-half_w * 0.5, -half_h * 0.5},
    }

    rotations := [4]f32{
         angle,
        -angle,
         angle,
        -angle,
    }

    for i := 0; i < 4; i += 1 {
        line_center := [2]f32{
            center[0] + offsets[i][0],
            center[1] + offsets[i][1],
        }

        AppendLineItem(
            line_center,
            edge_len,
            _thickness,
            rotations[i],
            _sort_layer,
            _color,
            _out_items,
        )
    }
}

// Appends the ghost preview tile for the currently hovered cell in paint mode.
@private
AppendHoverPreviewItem :: proc(
    _level: ^Level_State,
    _sort_layer: i32,
    _out_items: ^[dynamic]renderdata.Render_Item,
) {
    if !_level.editor.has_hovered_cell do return

    switch _level.editor.mode {
    case .Paint:
        if !_level.editor.has_selected_tile do return

        def, ok := GetTileDef(&_level.defsLibrary, _level.editor.selected_tile)
        if !ok do return

        pos := IsoGridCoordinateToWorldPos(_level.editor.hovered_cell, _level.resources.tile_w, _level.resources.tile_h)

        // Create the render item for the hover preview tile.
        item := renderdata.Render_Item{
            pass = .World,
            sort_layer = _sort_layer,
            y_sort = pos[1],

            material = renderdata.Material_Key{
                pipeline = .Sprite,
                texture  = def.texture,
                sampler  = def.sampler,
                blend    = .Alpha,
            },

            instance = renderdata.Sprite_Instance{
                model = renderdata.MakeSpriteModelMatrix(
                    pos,
                    def.size,
                    def.origin,
                    0,
                    0,
                ),
                uv_min = def.uv_min,
                uv_max = def.uv_max,
                color  = _level.editor.preview_color,
            },
        }

        append(_out_items, item)

    case .Delete:
        // No ghost tile in delete mode
    }
}


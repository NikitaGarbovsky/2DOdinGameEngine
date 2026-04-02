package tilemap

import "core:math"

///
/// Contains math converters for the tilemap coordinate positions & world positions
///


// ================ Helpers for conversions ================
IsoGridCoordinateToWorldPos :: proc(_cell : Tile_Coord, _tile_w, _tile_h : f32) -> [2]f32 {
    half_w := _tile_w * 0.5
    half_h := _tile_h * 0.5

    return {
        (f32(_cell.x) - f32(_cell.y)) * half_w,
        (f32(_cell.x) + f32(_cell.y)) * half_h,
    }
}

@private
WorldToIsoGridFloat :: proc(_pos : [2]f32, _tile_w, _tile_h : f32) -> [2]f32 {
    half_w := _tile_w * 0.5
    half_h := _tile_h * 0.5

    gx := ((_pos[0] / half_w) + (_pos[1] / half_h)) * 0.5
    gy := ((_pos[1] / half_h) - (_pos[0] / half_w)) * 0.5

    return {gx, gy}
}

WorldToIsoGridCoordinate :: proc(_pos : [2]f32, _tile_w, _tile_h : f32) -> Tile_Coord {
    // The passed in position will be an approixmation of where the tile on the tilemap could be,
    // (the user clicks within a tile somewhere, onhover etc)
    grid_f := WorldToIsoGridFloat(_pos, _tile_w, _tile_h)

    // So we round it to select that exact tile in the grid
    return Tile_Coord{
        x = i32(math.round(grid_f[0])),
        y = i32(math.round(grid_f[1])),
    }
}
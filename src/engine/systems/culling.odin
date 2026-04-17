package systems

import glm "core:math/linalg/glsl"
import omath "core:math"
import "../components"
import "../renderdata"
import "../tilemap"

// This is used by the system_Render.odin file to cull entities outside of the view frustrum
// A bunch of helper to calculate tilemap & entity positions.

@private
RectOverlaps :: proc(_a, _b : renderdata.Rect2D) -> bool {
    if _a.max[0] < _b.min[0] do return false
    if _a.min[0] > _b.max[0] do return false
    if _a.max[1] < _b.min[1] do return false
    if _a.min[1] > _b.max[1] do return false
    return true
}

@private
EntitySpriteWorldAABB :: proc(_transform : components.Transform, 
    _sprite : components.Sprite) -> renderdata.Rect2D {
        
    width := _sprite.size.x
    height := _sprite.size.y

    hw := width * 0.5
    hh := height * 0.5

    c := omath.cos(_transform.rot)
    sn := omath.sin(_transform.rot)

    // local center of the quad relative to the origin/pivot
    local_center := glm.vec2{
        (0.5 - _sprite.origin[0]) * width,
        (0.5 - _sprite.origin[1]) * height
    }

    world_center := glm.vec2{
        _transform.pos.x + local_center[0] * c - local_center[1] * sn,
        _transform.pos.y + local_center[0] * sn + local_center[1] * c,
    }

    ex := omath.abs(c) * hw + omath.abs(sn) * hh
    ey := omath.abs(sn) * hw + omath.abs(c) * hh

    return renderdata.Rect2D{
        min = glm.vec2{world_center[0] - ex, world_center[1] - ey},
        max = glm.vec2{world_center[0] + ex, world_center[1] + ey},
    }
}

@private
IsEntitySpriteVisible :: proc(_cam : ^renderdata.Camera2D, 
    _transform : components.Transform, 
    _sprite : components.Sprite,
    _cullCount : ^int) -> bool
{
    cam_rect := renderdata.CameraWorldRect(_cam)
    sprite_rect := EntitySpriteWorldAABB(_transform, _sprite)
    overlaps := RectOverlaps(cam_rect, sprite_rect)
    if overlaps do return true 
    if !overlaps {
        _cullCount^ += 1
        return false
    }
    return false
}

@private
TileMapTileAABB :: proc(world_pos: [2]f32, def: ^tilemap.Tile_Definition) -> renderdata.Rect2D {
    width  := def.size[0]
    height := def.size[1]

    min_x := world_pos[0] - def.origin[0] * width
    min_y := world_pos[1] - def.origin[1] * height
    max_x := min_x + width
    max_y := min_y + height

    return renderdata.Rect2D{
        min = glm.vec2{min_x, min_y},
        max = glm.vec2{max_x, max_y},
    }
}

@private
IsTileVisible :: proc(_cam: ^renderdata.Camera2D, 
    _world_pos: [2]f32, 
    _def: ^tilemap.Tile_Definition,
    _cullCount : ^int) -> bool 
{
    cam_rect  := renderdata.CameraWorldRect(_cam)
    tile_rect := TileMapTileAABB(_world_pos, _def)

    overlaps := RectOverlaps(cam_rect, tile_rect)

    if overlaps do return true 
    if !overlaps {
        _cullCount^ += 1
        return false
    }
    return false
}

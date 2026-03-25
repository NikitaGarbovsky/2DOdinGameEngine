package systems

import glm "core:math/linalg/glsl"
import "../components"
import "../renderer"
import omath "core:math"

@private
RectOverlaps :: proc(_a, _b : renderer.Rect2D) -> bool {
    if _a.max[0] < _b.min[0] do return false
    if _a.min[0] > _b.max[0] do return false
    if _a.max[1] < _b.min[1] do return false
    if _a.min[1] > _b.max[1] do return false
    return true
}

@private
SpriteWorldAABB :: proc(_transform : components.Transform, 
    _sprite : components.Sprite) -> renderer.Rect2D {
        
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

    return renderer.Rect2D{
        min = glm.vec2{world_center[0] - ex, world_center[1] - ey},
        max = glm.vec2{world_center[0] + ex, world_center[1] + ey},
    }
}

IsSpriteVisible :: proc(_cam : ^renderer.Camera2D, 
    _transform : components.Transform, 
    _sprite : components.Sprite) -> bool
{
    cam_rect := renderer.CameraWorldRect(_cam)
    sprite_rect := SpriteWorldAABB(_transform, _sprite)
    return RectOverlaps(cam_rect, sprite_rect)
}
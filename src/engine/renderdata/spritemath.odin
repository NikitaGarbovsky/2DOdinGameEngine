package renderdata

import glm "core:math/linalg/glsl"

MakeSpriteModelMatrix :: proc(pos : [2]f32,
size : [2]f32, origin : [2]f32, rot : f32, layer : f32) -> glm.mat4 {
    t_world := glm.mat4Translate({pos[0], pos[1], layer})
    r := glm.mat4Rotate({0,0,1}, rot)
    s := glm.mat4Scale({size[0], size[1], 1})
    t_pivot := glm.mat4Translate({-origin[0], -origin[1], 0})

    return t_world * r * s * t_pivot
}
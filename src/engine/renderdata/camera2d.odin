package renderdata

import glm "core:math/linalg/glsl"

CameraSetZoom :: proc(_cam : ^Camera2D, _zoom : f32) {
    _cam.zoom = max(0.05, _zoom)
}

CameraAddZoom :: proc(_cam : ^Camera2D, _delta : f32) {
    _cam.zoom = max(0.05, _cam.zoom + _delta)
}

CameraViewMatrix :: proc(_cam : ^Camera2D) -> glm.mat4 {
    half_view := glm.vec3 {
        _cam.viewport_size[0] * 0.5,
        _cam.viewport_size[1] * 0.5,
        0,
    }

    to_screen_center := glm.mat4Translate(half_view)
    zoom := glm.mat4Scale(glm.vec3{_cam.zoom, _cam.zoom, 1})
    move_world := glm.mat4Translate(glm.vec3{-_cam.position[0], -_cam.position[1], 0})

    return to_screen_center * zoom * move_world
}

CameraProjMatrix :: proc(_cam : ^Camera2D) -> glm.mat4 {
    return glm.mat4Ortho3d(0, _cam.viewport_size[0], _cam.viewport_size[1],
    0, -1, 1)
}

CameraViewProjMatrix :: proc(_cam : ^Camera2D) -> glm.mat4 {
    return CameraProjMatrix(_cam) * CameraViewMatrix(_cam)
}

CameraWorldRect :: proc(_cam : ^Camera2D) -> Rect2D {
    half_w := (_cam.viewport_size[0] * 0.5) / _cam.zoom
    half_h := (_cam.viewport_size[1] * 0.5) / _cam.zoom

    return Rect2D{
        min = glm.vec2{_cam.position[0] - half_w, _cam.position[1] - half_h},
        max = glm.vec2{_cam.position[0] + half_w, _cam.position[1] + half_h},
    }
}
#+vet explicit-allocators
package renderdata

import glm "core:math/linalg/glsl"

///
/// Bunch of helpers to manage 2D Camera functionality
///

// Used by input mouse scroll
CameraZoomIn :: proc(_cam : ^Camera2D, _delta : f32) {
    _cam.zoom = min(3, _cam.zoom + _delta / 10)
}

// Used by input mouse scroll
CameraZoomOut :: proc(_cam : ^Camera2D, _delta : f32) {
    _cam.zoom = max(1, _cam.zoom + _delta / 10)
}

// Returns the view matrix of the 2D camera
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

// Returns the projection matrix for the camera.
CameraProjMatrix :: proc(_cam : ^Camera2D) -> glm.mat4 {
    return glm.mat4Ortho3d(0, _cam.viewport_size[0], _cam.viewport_size[1],
    0, -1, 1)
}

// Returns the viewproj matrix of the camerea, this is primarily used 
// for passing this to the renderer for shaders
CameraViewProjMatrix :: proc(_cam : ^Camera2D) -> glm.mat4 {
    return CameraProjMatrix(_cam) * CameraViewMatrix(_cam)
}

// Returns a rect of the screen viewport size. Used for renderer culling.
CameraWorldRect :: proc(_cam : ^Camera2D) -> Rect2D {
    half_w := (_cam.viewport_size[0] * 0.5) / _cam.zoom
    half_h := (_cam.viewport_size[1] * 0.5) / _cam.zoom

    return Rect2D{
        min = glm.vec2{_cam.position[0] - half_w, _cam.position[1] - half_h},
        max = glm.vec2{_cam.position[0] + half_w, _cam.position[1] + half_h},
    }
}

// Converts 2D screenspace position to 2D world position
ScreenToWorldPos :: proc(_cam : ^Camera2D, _screenPos : [2]f32) -> [2]f32 {

    // Gets the center of the screen in pixels
    half_x := _cam.viewport_size[0] * 0.5 // x
    half_y := _cam.viewport_size[1] * 0.5 // y

    // Take screen pos, shift it so center becomes 0, (relavite positioning)
    // divide by zoom to account for it, add original camera position 
    return {
        _cam.position[0] + (_screenPos[0] - half_x) / _cam.zoom, // x
        _cam.position[1] + (_screenPos[1] - half_y) / _cam.zoom, // y
    }
}

// Converts 2D worldspace position to 2D screenspace position
WorldToScreenPos :: proc(
    _camera : ^Camera2D,
    _viewport_size : [2]f32,
    _world_pos : [2]f32,
) -> [2]f32 {
    screen_x := (_world_pos.x - _camera.position.x) * _camera.zoom + _viewport_size.x * 0.5
    screen_y := (_world_pos.y - _camera.position.y) * _camera.zoom + _viewport_size.y * 0.5

    return {screen_x, screen_y}
}
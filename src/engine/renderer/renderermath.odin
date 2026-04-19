#+vet explicit-allocators
package renderer

import glm "core:math/linalg/glsl"

// #TODO: comment this 

// Top-left origin, +y downward (sdl3 gpu standard :( )
MakeOrthoProjection :: proc(_width, _height : f32) -> glm.mat4 {
    return glm.mat4Ortho3d(0, _width, _height, 0, -1, 1)
}
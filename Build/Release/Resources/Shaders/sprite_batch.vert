#version 460

layout(location = 0) in vec2 in_local_pos;
layout(location = 1) in vec2 in_base_uv;
// This is passed in as 4 x floats, somehow on the way to gpu
// it turns into a single mat4, not really sure why, but it works?
layout(location = 2) in mat4 in_modelMat;
layout(location = 6) in vec2 in_uv_min;
layout(location = 7) in vec2 in_uv_max;
layout(location = 8) in vec4 in_color;

layout(set = 1, binding = 0, std140) uniform SpriteGlobalVS {
    mat4 view_proj;
} ubo;

layout(location = 0) out vec2 v_uv;
layout(location = 1) out vec4 v_color;

void main() {
    // Grab local pos
    vec4 local = vec4(in_local_pos, 0.0, 1.0);

    // Set position 
    gl_Position = ubo.view_proj * in_modelMat * local;

    v_uv = mix(in_uv_min, in_uv_max, in_base_uv);
    v_color = in_color;
}
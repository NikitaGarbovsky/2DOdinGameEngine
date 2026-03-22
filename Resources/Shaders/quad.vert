#version 460

layout(set = 1, binding = 0, std140) uniform QuadVS {
    vec2 pos;
    vec2 size; 
    float rotation;
    vec2 viewportSize;
} ubo;

// Tempt shader just to get the quads on the screen and visible 
// #TODO: Don't use this and try map positions to matrices that you
// pass via uniform into here instead of doing position calculations in here

void main() {
    // Two triangles that will make up the quad
    vec2 corners[6] = vec2[](
        vec2(-0.5, -0.5),
        vec2(0.5, -0.5),
        vec2(0.5, 0.5),

        vec2(-0.5, -0.5),
        vec2(0.5, 0.5),
        vec2(-0.5, 0.5)
    );

    
    vec2 local = corners[gl_VertexIndex] * ubo.size.xy;

    // Rotation cacluation (radians)
    float c = cos(ubo.rotation);
    float s = sin(ubo.rotation);

    // Rotation applied
    vec2 rotated = vec2(
        local.x * c - local.y * s,
        local.x * s + local.y * c
    );
    
    vec2 world = ubo.pos.xy + rotated;

    float view_w = ubo.viewportSize.x;
    float view_h = ubo.viewportSize.y;

    vec2 ndc; // map world positions to ndc
    ndc.x = (world.x / view_w) * 2.0 - 1.0;
    ndc.y = 1.0 - (world.y / view_h) * 2.0;

    gl_Position = vec4(ndc, 0.0, 1.0);
}
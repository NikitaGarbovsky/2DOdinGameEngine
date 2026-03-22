#version 460

layout(set = 3, binding = 0, std140) uniform QuadFS {
    vec4 color;
} ubo;

layout(location = 0) out vec4 FinalColor;

void main() {
    FinalColor = ubo.color;
}
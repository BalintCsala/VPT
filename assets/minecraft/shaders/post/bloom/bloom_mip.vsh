#version 420

#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:settings.glsl>

const vec2[] OFFSETS = vec2[](
    vec2(-1.0, 1.0),
    vec2(1.0, -1.0),
    vec2(1.0, 1.0)
);

void main() {
    vec2 scale = (ScreenSize + 2) / vec2(MAX_RESOLUTION);
    gl_Position = vec4(OFFSETS[gl_VertexID] * scale * 2.0 - 1.0, 0.0, 1.0);
}
#version 420

out vec2 texCoord;

const vec2[] OFFSETS = vec2[](
        vec2(-1.0, 1.0),
        vec2(1.0, -1.0),
        vec2(1.0, 1.0)
    );

void main() {
    vec2 scale = vec2(1.0);
    #ifdef SCALE
    scale = vec2(SCALE);
    #endif

    gl_Position = vec4(OFFSETS[gl_VertexID] * scale * 2.0 - 1.0, 0.0, 1.0);
    texCoord = (gl_Position.xy * 0.5 + 0.5) / scale;
}

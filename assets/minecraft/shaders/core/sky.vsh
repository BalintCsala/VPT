#version 420

const vec4[] VERTEX_POSITIONS = vec4[](
    vec4(-1.0, -1.0, 0.0, 1.0),
    vec4(1.0, -1.0, 0.0, 1.0),
    vec4(1.0, 1.0, 0.0, 1.0),
    vec4(-1.0, 1.0, 0.0, 1.0)
);

void main() {
    if (gl_VertexID >= 4) {
        gl_Position = vec4(-1.0);
        return;
    }
    gl_Position = VERTEX_POSITIONS[gl_VertexID % 4];
}

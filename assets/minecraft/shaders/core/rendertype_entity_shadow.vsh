#version 420

in vec4 Position;

void main() {
    gl_Position = -Position;
}

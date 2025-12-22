#version 420

uniform sampler2D Sampler0;

out vec4 fragColor;

void main() {
    fragColor = texture(Sampler0, gl_FragCoord.xy);
}

#version 420

uniform sampler2D MainSampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    fragColor = texelFetch(MainSampler, ivec2(gl_FragCoord.xy), 0);
}

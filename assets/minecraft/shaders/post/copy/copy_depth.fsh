#version 420

uniform sampler2D DepthSampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    uint scaled = uint(floor(texelFetch(DepthSampler, ivec2(gl_FragCoord.xy), 0).r * 16777215.0));
    fragColor = unpackUnorm4x8(scaled);
}

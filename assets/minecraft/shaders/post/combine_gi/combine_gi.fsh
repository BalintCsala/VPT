#version 420

#moj_import <minecraft:rendering/tonemap.glsl>
#moj_import <minecraft:utilities/colors.glsl>

uniform sampler2D DirectLightSampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    vec3 directLight = decodeHDR(textureLod(DirectLightSampler, texCoord, 0.0));

    vec3 radiance = directLight;
    fragColor = encodeHDR(radiance);
}


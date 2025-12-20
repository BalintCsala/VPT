#version 420

#moj_import <minecraft:rendering/tonemap.glsl>
#moj_import <minecraft:utilities/colors.glsl>

uniform sampler2D DirectSampler;
uniform sampler2D BloomSampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    vec3 radiance = decodeHDR(texelFetch(DirectSampler, ivec2(gl_FragCoord.xy), 0));
    vec3 bloom = decodeHDR(texelFetch(BloomSampler, ivec2(gl_FragCoord.xy), 0));
    vec3 result = tonemap(radiance + bloom * 0.003);
    result = linearToSrgb(result);
    fragColor = vec4(result, 1.0);
}

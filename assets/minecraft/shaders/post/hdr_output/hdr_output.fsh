#version 420

#moj_import <minecraft:rendering/tonemap.glsl>
#moj_import <minecraft:utilities/colors.glsl>

uniform sampler2D DirectSampler;
uniform sampler2D DiffuseGISampler;
uniform sampler2D BloomSampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    vec3 radiance = decodeHDR(texelFetch(DirectSampler, pixel, 0));
    vec3 diffuseGI = decodeHDR(texelFetch(DiffuseGISampler, pixel / 4, 0));
    vec3 bloom = decodeHDR(texelFetch(BloomSampler, pixel, 0));
    vec3 result = tonemap(radiance + diffuseGI + bloom * 0.01);
    result = linearToSrgb(result);
    fragColor = vec4(result, 1.0);
}

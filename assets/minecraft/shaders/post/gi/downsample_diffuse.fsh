#version 420

#moj_import <minecraft:utilities/colors.glsl>

uniform sampler2D DiffuseGISampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    ivec2 rootPixel = ivec2(gl_FragCoord.xy) * ivec2(4, 2);
    vec3 radiance = vec3(0.0);
    radiance += decodeHDR(texelFetchOffset(DiffuseGISampler, rootPixel, 0, ivec2(0, 0)));
    radiance += decodeHDR(texelFetchOffset(DiffuseGISampler, rootPixel, 0, ivec2(1, 0)));
    radiance += decodeHDR(texelFetchOffset(DiffuseGISampler, rootPixel, 0, ivec2(2, 0)));
    radiance += decodeHDR(texelFetchOffset(DiffuseGISampler, rootPixel, 0, ivec2(3, 0)));
    radiance += decodeHDR(texelFetchOffset(DiffuseGISampler, rootPixel, 0, ivec2(0, 1)));
    radiance += decodeHDR(texelFetchOffset(DiffuseGISampler, rootPixel, 0, ivec2(1, 1)));
    radiance += decodeHDR(texelFetchOffset(DiffuseGISampler, rootPixel, 0, ivec2(2, 1)));
    radiance += decodeHDR(texelFetchOffset(DiffuseGISampler, rootPixel, 0, ivec2(3, 1)));
    radiance /= 8.0;
    fragColor = encodeHDR(radiance);
}

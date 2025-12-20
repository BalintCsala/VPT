#version 420

#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:utilities/colors.glsl>

uniform sampler2D InSampler;

out vec4 fragColor;

void main() {
    ivec2 baseFragCoord = ivec2(floor(gl_FragCoord.xy)) * 2;
    vec3 color = vec3(0.0);

    // This is intentionally cursed
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2(-1, -1)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 0, -1)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 1, -1)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 2, -1)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2(-1,  0)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 0,  0)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 1,  0)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 2,  0)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2(-1,  1)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 0,  1)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 1,  1)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 2,  1)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2(-1,  2)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 0,  2)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 1,  2)));
    color += decodeHDR(texelFetchOffset(InSampler, baseFragCoord, 0, ivec2( 2,  2)));
    color /= 16.0;

    fragColor = encodeHDR(color);
}
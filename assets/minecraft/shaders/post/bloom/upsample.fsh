#version 420

#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:utilities/colors.glsl>

uniform sampler2D PreviousMipSampler;
uniform sampler2D CurrentMipSampler;

out vec4 fragColor;

void main() {
    ivec2 pixelCoord = ivec2(floor(gl_FragCoord.xy / 2.0 - 0.5));
    vec2 mixingParam = fract(gl_FragCoord.xy / 2.0 - 0.5);

    vec3 blurredPrevMip = mix(
            mix(
                decodeHDR(texelFetch(PreviousMipSampler, pixelCoord + ivec2(0, 0), 0)),
                decodeHDR(texelFetch(PreviousMipSampler, pixelCoord + ivec2(1, 0), 0)),
                mixingParam.x
            ),
            mix(
                decodeHDR(texelFetch(PreviousMipSampler, pixelCoord + ivec2(0, 1), 0)),
                decodeHDR(texelFetch(PreviousMipSampler, pixelCoord + ivec2(1, 1), 0)),
                mixingParam.x
            ),
            mixingParam.y
        );
    vec3 currMip = decodeHDR(texelFetch(CurrentMipSampler, ivec2(gl_FragCoord.xy), 0));
    fragColor = encodeHDR(blurredPrevMip * 0.9 + currMip);
}


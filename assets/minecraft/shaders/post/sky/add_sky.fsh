#version 420

#moj_import <minecraft:utilities/colors.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:utilities/colors.glsl>
#moj_import <minecraft:utilities/random.glsl>

uniform sampler2D DepthSampler;
uniform sampler2D SkySampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    vec2 scaledTexCoord = texCoord * vec2(0.5, 1.0);
    float depth = textureLod(DepthSampler, scaledTexCoord, 0.0).r;

    if (depth != 1.0) {
        // Not sky
        discard;
        return;
    }

    ivec2 pixelCoord = ivec2(floor(gl_FragCoord.xy / 2.0 - 0.5));
    vec2 mixingParam = fract(gl_FragCoord.xy / 2.0 - 0.5);

    vec3 sky = mix(
            mix(
                decodeHDR(texelFetch(SkySampler, pixelCoord + ivec2(0, 0), 0)),
                decodeHDR(texelFetch(SkySampler, pixelCoord + ivec2(1, 0), 0)),
                mixingParam.x
            ),
            mix(
                decodeHDR(texelFetch(SkySampler, pixelCoord + ivec2(0, 1), 0)),
                decodeHDR(texelFetch(SkySampler, pixelCoord + ivec2(1, 1), 0)),
                mixingParam.x
            ),
            mixingParam.y
        );

    uint randState = initRNG(uvec2(gl_FragCoord.xy), uvec2(ScreenSize), uint(GameTime * 20.0 * 60.0 * 300.0));
    fragColor = encodeHDR(sky + randFloat(randState) * 0.01);
}

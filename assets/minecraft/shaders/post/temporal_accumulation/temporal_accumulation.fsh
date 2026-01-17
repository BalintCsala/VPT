#version 420

#moj_import <minecraft:utilities/colors.glsl>
#moj_import <minecraft:math/space_conversions.glsl>
#moj_import <minecraft:globals.glsl>

uniform sampler2D DepthSampler;
uniform sampler2D PreviousDepthSampler;
uniform sampler2D CurrentSampler;
uniform sampler2D PreviousSampler;

flat in mat4 proj;
flat in mat4 projInv;
flat in mat4 view;
flat in mat4 viewInv;
flat in vec3 cameraOffset;
flat in mat4 prevProj;
flat in mat4 prevView;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    vec4 raw = texelFetch(CurrentSampler, ivec2(gl_FragCoord.xy), 0);
    float depth = textureLod(DepthSampler, texCoord * vec2(0.5, 1.0), 0.0).r;
    if (depth == 1.0) {
        fragColor = encodeHDR(vec3(0.0));
        return;
    }

    vec3 screenPos = vec3(texCoord, depth);
    vec3 playerPos = screenToPlayer(viewInv, projInv, screenPos);
    vec3 prevPlayerPos = playerPos + cameraOffset;
    vec4 prevClipPos = prevProj * prevView * vec4(prevPlayerPos, 1.0);
    if (clamp(prevClipPos.xyz, -prevClipPos.w, prevClipPos.w) != prevClipPos.xyz) {
        fragColor = raw;
        return;
    }
    vec3 prevScreenPos = prevClipPos.xyz / prevClipPos.w * 0.5 + 0.5;
    float prevDepth = float(packUnorm4x8(textureLod(PreviousDepthSampler, prevScreenPos.xy * vec2(0.5, 1.0), 0.0))) / 16777215.0;
    if (abs(prevDepth / (1.005 - prevDepth) - prevScreenPos.z / (1.005 - prevScreenPos.z)) > 2.0) {
        fragColor = raw;
        return;
    }

    vec3 current = decodeHDR(raw);

    vec2 pixelPos = prevScreenPos.xy * 0.25 * ScreenSize - 0.5;
    ivec2 integerPixelPos = ivec2(floor(pixelPos));
    vec2 fractionalPixelPos = fract(pixelPos);
    vec3 prev = mix(
            mix(
                decodeHDR(texelFetchOffset(PreviousSampler, integerPixelPos, 0, ivec2(0, 0))),
                decodeHDR(texelFetchOffset(PreviousSampler, integerPixelPos, 0, ivec2(1, 0))),
                fractionalPixelPos.x
            ),
            mix(
                decodeHDR(texelFetchOffset(PreviousSampler, integerPixelPos, 0, ivec2(0, 1))),
                decodeHDR(texelFetchOffset(PreviousSampler, integerPixelPos, 0, ivec2(1, 1))),
                fractionalPixelPos.x
            ),
            fractionalPixelPos.y
        );

    fragColor = encodeHDR(mix(prev, current, 0.05));
}

#version 420

#moj_import <rendering/atmosphere.glsl>
#moj_import <math/space_conversions.glsl>
#moj_import <minecraft:utilities/colors.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:utilities/random.glsl>

vec3 GROUND_COLOR = srgbToLinear(vec3(0.19, 0.17, 0.16)) * LIGHT_INTENSITY * 1.0;

uniform sampler2D DepthSampler;

in mat4 projMat;
in mat4 projMatInv;
in mat4 viewMat;
in mat4 viewMatInv;
in vec3 sunDirection;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    uint randState = initRNG(uvec2(gl_FragCoord.xy), uvec2(ScreenSize), uint(GameTime * 20.0 * 60.0 * 300.0));
    vec2 scaledTexCoord = texCoord * vec2(0.5, 1.0);
    float depth = textureLod(DepthSampler, scaledTexCoord, 0.0).r;

    vec3 fragmentPos = screenToPlayer(viewMatInv, projMatInv, vec3(texCoord, depth)) - fract(CameraOffset);
    vec3 nearPlanePos = screenToPlayer(viewMatInv, projMatInv, vec3(texCoord, 0.0)) - fract(CameraOffset);

    vec3 rayDir = normalize(fragmentPos - nearPlanePos);
    vec3 sunDir = normalize(sunDirection);

    vec3 rayOrigin = vec3(0.0, PLANET_RADIUS + 1.8, 0.0);
    vec3 sky = atmosphere(rayOrigin, rayDir, sunDir, randFloat(randState)) * LIGHT_INTENSITY;
    vec3 ground = smoothstep(0.0, 0.1, sunDir.y) * (1.0 - smoothstep(0.0, 0.1, rayDir.y)) * GROUND_COLOR;
    fragColor = encodeHDR(sky + ground);
}

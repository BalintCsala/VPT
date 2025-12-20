#define MAX_STEPS 4

#moj_import <minecraft:rendering/models.glsl>
#moj_import <minecraft:rendering/pbr/material.glsl>
#moj_import <minecraft:math/space_conversions.glsl>
#moj_import <minecraft:rendering/raytrace.glsl>
#moj_import <minecraft:globals.glsl>

uniform sampler2D DataSampler;
uniform sampler2D DataDepthSampler;
uniform sampler2D AtlasSampler;
uniform sampler2D ModelDataSampler;

in mat4 projMat;
in mat4 projMatInv;
in mat4 viewMat;
in mat4 viewMatInv;

in vec2 texCoord;

out vec4 fragColor;

vec4 hit(vec2 texCoord, float depth, Intersection intersection);

vec4 miss(vec2 texCoord, float depth);

void main() {
    vec2 scaledTexCoord = texCoord * vec2(0.5, 1.0);

    float depth = textureLod(DataDepthSampler, scaledTexCoord, 0.0).r;

    if (depth == 1.0) {
        // Sky
        fragColor = vec4(0.0);
        return;
    }

    vec3 fragmentPos = screenToPlayer(viewMatInv, projMatInv, vec3(texCoord, depth)) - fract(CameraOffset);
    vec3 nearPlanePos = screenToPlayer(viewMatInv, projMatInv, vec3(texCoord, 0.0)) - fract(CameraOffset);

    vec3 rayDir = normalize(fragmentPos - nearPlanePos);
    vec3 origin = fragmentPos - rayDir * 0.1;

    Ray ray = createRayFromSinglePosition(origin, rayDir);
    Intersection intersection = raytrace(DataDepthSampler, DataSampler, ModelDataSampler, AtlasSampler, ray);
    if (!intersection.hit || intersection.t > 0.15) {
        // Missing block or entity
        fragColor = miss(texCoord, depth);
        return;
    }

    fragColor = hit(texCoord, depth, intersection);
}

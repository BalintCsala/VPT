#version 420

#moj_import <minecraft:rendering/raytrace.glsl>
#moj_import <minecraft:rendering/models.glsl>
#moj_import <minecraft:rendering/tonemap.glsl>
#moj_import <minecraft:utilities/colors.glsl>
#moj_import <minecraft:rendering/pbr/brdf.glsl>
#moj_import <minecraft:rendering/pbr/material.glsl>
#moj_import <minecraft:rendering/atmosphere.glsl>
#moj_import <minecraft:hacks.glsl>

uniform sampler2D DataSampler;
uniform sampler2D DepthSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D AtlasSampler;
uniform sampler2D ModelDataSampler;
uniform sampler2D Material1Sampler;
uniform sampler2D Material2Sampler;
uniform sampler2D TranslucentMaterial1Sampler;
uniform sampler2D TranslucentMaterial2Sampler;

flat in mat4 proj;
flat in mat4 projInv;
flat in mat4 view;
flat in mat4 viewInv;
flat in vec3 sunDirection;
flat in float sunInfo;
flat in vec3 lightIntensity;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    vec2 scaledTexCoord = texCoord * vec2(0.5, 1.0);
    vec3 albedo = srgbToLinear(textureLod(DataSampler, scaledTexCoord, 0.0).rgb);

    float depth = textureLod(DepthSampler, scaledTexCoord, 0.0).r;
    float translucentDepth = textureLod(TranslucentDepthSampler, scaledTexCoord, 0.0).r;

    if (depth > translucentDepth) {
        // Water or stained glass, don't shade here
        fragColor = encodeHDR(vec3(0.0));
        return;
    }

    if (depth == 1.0) {
        // Sky
        fragColor = encodeHDR(vec3(0.0));
        return;
    }

    vec4 material1 = textureLod(Material1Sampler, texCoord, 0.0);
    vec4 material2 = textureLod(Material2Sampler, texCoord, 0.0);
    vec3 geometryNormal = getGeometryNormal(material1);
    Material material = decodeScreenMaterial(albedo, material1, material2);

    vec4 screenPos = vec4(texCoord, depth, 1.0);
    vec4 tmp = viewInv * projInv * (screenPos * 2.0 - 1.0);
    vec3 playerPos = tmp.xyz / tmp.w;

    vec3 hitPos = playerPos - fract(CameraOffset) + material.normal * 0.001;
    ivec3 voxelPos = ivec3(floor(hitPos));

    vec3 sunDir = normalize(sunDirection);
    float NdotL = clamp(dot(material.normal, sunDir), 0.0, 1.0);

    vec3 radiance = material.emission;
    if (NdotL > 0.001) {
        Ray sunRay = Ray(voxelPos, hitPos, sunDir);
        Intersection sunIntersection = raytrace(DepthSampler, DataSampler, ModelDataSampler, AtlasSampler, sunRay);
        if (!sunIntersection.hit) {
            vec3 startPos = playerPos + sunIntersection.t * sunDir;
            vec3 endPos = startPos + sunDir * 32.0;
            SSRTResult result = raytraceSSFromPlayer(DepthSampler, startPos, endPos, view, proj, projInv, 0.1, 12, 0, 0.3, false);
            if (!result.hit) {
                vec3 view = -normalize(playerPos);
                radiance += brdf(material, material.normal, view, sunDir, NdotL) * lightIntensity * NdotL;
            }
        }
    }

    fragColor = encodeHDR(radiance);
}

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

in mat4 projMat;
in mat4 projMatInv;
in mat4 viewMat;
in mat4 viewMatInv;
in vec3 sunDirection;
in float sunInfo;
in vec3 lightIntensity;

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
    vec4 tmp = viewMatInv * projMatInv * (screenPos * 2.0 - 1.0);
    vec3 playerPos = tmp.xyz / tmp.w;

    vec3 hitPos = playerPos - fract(CameraOffset) + material.normal * 0.001;
    ivec3 voxelPos = ivec3(floor(hitPos));

    vec3 sunDir = normalize(sunDirection);
    float NdotL = clamp(dot(material.normal, sunDir), 0.0, 1.0);

    vec3 radiance = AMBIENT_FACTOR * albedo * (1.0 - material.metallic) * material.ambientOcclusion + material.emission;
    if (NdotL > 0.001) {
        vec3 intensity = lightIntensity;
        if (sunInfo >= 2.0) {
            intensity = vec3(0.7, 0.16, 0.82) * 1.8 * (sunInfo - 2.0);
        }

        Ray sunRay = Ray(voxelPos, hitPos, sunDir);
        Intersection sunIntersection = raytrace(DepthSampler, DataSampler, ModelDataSampler, AtlasSampler, sunRay);
        if (!sunIntersection.hit) {
            vec3 view = -normalize(playerPos);
            radiance += brdf(material, material.normal, view, sunDir, NdotL) * intensity * NdotL;
        }
    }

    fragColor = encodeHDR(radiance);
}

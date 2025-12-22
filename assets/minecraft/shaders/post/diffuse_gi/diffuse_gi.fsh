#version 420

#moj_import <minecraft:rendering/raytrace.glsl>
#moj_import <minecraft:rendering/models.glsl>
#moj_import <minecraft:rendering/tonemap.glsl>
#moj_import <minecraft:utilities/colors.glsl>
#moj_import <minecraft:rendering/pbr/brdf.glsl>
#moj_import <minecraft:rendering/pbr/material.glsl>
#moj_import <minecraft:globals.glsl>

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

in vec2 texCoord;

out vec4 fragColor;

const vec3 LIGHT_INTENSITY = vec3(1, 0.75, 0.28) * 2.5;
const vec3 SKYLIGHT_INTENSITY = vec3(0.81, 0.89, 1) * 0.3;

void main() {
    // Make sure GI only runs at 0.25x resolution
    vec2 txCoord = texCoord * 4.0;
    if (clamp(txCoord, 0.0, 1.0) != txCoord) {
        fragColor = encodeHDR(vec3(0.0));
        return;
    }

    vec2 scaledTexCoord = txCoord * vec2(0.5, 1.0);
    vec3 albedo = srgbToLinear(textureLod(DataSampler, scaledTexCoord, 0.0).rgb);

    float depth = textureLod(DepthSampler, scaledTexCoord, 0.0).r;
    float translucentDepth = textureLod(TranslucentDepthSampler, scaledTexCoord, 0.0).r;
    bool translucent = false;

    Material material;
    if (translucentDepth < depth) {
        depth = translucentDepth;

        // We assume water and glass, fake some material properties accordingly
        material.albedo = vec3(0.0);
        material.F0 = vec3(0.02);
        material.roughness = 0.01;
        material.metallic = 0.0;
        material.ambientOcclusion = 0.0;
        material.emission = vec3(0.0);
        material.normal = getNormal(textureLod(TranslucentMaterial1Sampler, txCoord, 0.0).rgb);
    } else {
        //vec3 geometryNormal = textureLod(NormalSampler, txCoord, 0.0).rgb * 2.0 - 1.0;
        //material = decodeReducedMaterial(textureLod(MaterialMapSampler, txCoord, 0.0), albedo, geometryNormal);
        // TODO
    }

    if (material.metallic > 0.5) {
        fragColor = encodeHDR(vec3(0.0));
        return;
    }

    if (depth == 1.0) {
        // Sky
        fragColor = encodeHDR(vec3(0.0));
        return;
    }

    vec4 screenPos = vec4(txCoord, depth, 1.0);
    vec4 tmp = viewMatInv * projMatInv * (screenPos * 2.0 - 1.0);
    vec3 playerPos = tmp.xyz / tmp.w;

    Ray ray;
    {
        vec3 hitPos = playerPos - fract(CameraOffset) + material.normal * 0.001;
        ivec3 voxelPos = ivec3(floor(hitPos));
        ray = Ray(voxelPos, hitPos, vec3(0.0));
    }

    vec3 view = -normalize(playerPos);

    uint state = initRNG(uvec2(gl_FragCoord.xy), uvec2(ScreenSize), uint(GameTime * 20.0 * 60.0 * 240.0));

    vec3 radiance = vec3(0.0);
    vec3 throughput = vec3(1.0);
    for (int i = 0; i < 3; i++) {
        BRDFSample samp = sampleDiffuse(material, material.normal, state);
        ray.direction = samp.direction;
        if (i != 0) {
            throughput *= samp.throughput;
        }
        Intersection intersection = raytrace(DepthSampler, DataSampler, ModelDataSampler, AtlasSampler, ray);

        if (!intersection.hit) {
            radiance += throughput * SKYLIGHT_INTENSITY;
            break;
        }

        material = readMaterialFromAtlas(AtlasSampler, intersection.uv, intersection.tbn);
        radiance += throughput * material.emission;
        vec3 hitPos = ray.origin + ray.direction * intersection.t;

        if (dot(intersection.tbn[2], sunDirection) > 0.0) {
            Ray sunRay = Ray(intersection.voxelPos, hitPos, sunDirection);
            Intersection sunIntersection = raytrace(DepthSampler, DataSampler, ModelDataSampler, AtlasSampler, sunRay);
            if (!sunIntersection.hit) {
                float NdotL = clamp(dot(material.normal, normalize(sunDirection)), 0.0, 1.0);
                radiance += throughput * brdf(material, material.normal, -ray.direction, sunDirection, NdotL) * LIGHT_INTENSITY * NdotL;
            }
        }

        ray.voxelPos = intersection.voxelPos;
        ray.origin = hitPos;
    }

    fragColor = encodeHDR(radiance);
}

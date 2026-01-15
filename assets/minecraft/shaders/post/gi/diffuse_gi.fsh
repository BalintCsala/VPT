#version 420

#moj_import <minecraft:rendering/raytrace.glsl>
#moj_import <minecraft:rendering/models.glsl>
#moj_import <minecraft:rendering/tonemap.glsl>
#moj_import <minecraft:utilities/colors.glsl>
#moj_import <minecraft:rendering/pbr/brdf.glsl>
#moj_import <minecraft:rendering/pbr/material.glsl>
#moj_import <minecraft:rendering/atmosphere.glsl>
#moj_import <minecraft:math/space_conversions.glsl>
#moj_import <minecraft:globals.glsl>

uniform sampler2D DataSampler;
uniform sampler2D DepthSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D AtlasSampler;
uniform sampler2D ModelDataSampler;
uniform sampler2D Material1Sampler;
uniform sampler2D Material2Sampler;

in mat4 projMat;
in mat4 projMatInv;
in mat4 viewMat;
in mat4 viewMatInv;
in vec3 sunDirection;
in vec3 lightIntensity;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    // Round pixels down to 4x4 chunks
    ivec2 parentPixel = ivec2(gl_FragCoord.xy) / ivec2(4, 2) * 4;

    float depth = texelFetch(DepthSampler, parentPixel / ivec2(2, 1), 0).r;
    if (depth == 1.0) {
        // Sky
        fragColor = encodeHDR(vec3(0.0));
        return;
    }

    vec3 screenPos = vec3(vec2(parentPixel) / ScreenSize, depth);
    vec3 playerPos = screenToPlayer(viewMatInv, projMatInv, screenPos);

    vec3 albedo = srgbToLinear(texelFetch(DataSampler, parentPixel / ivec2(2, 1), 0).rgb);
    vec4 material1 = texelFetch(Material1Sampler, parentPixel, 0);
    vec4 material2 = texelFetch(Material2Sampler, parentPixel, 0);
    vec3 geometryNormal = getGeometryNormal(material1);
    Material material = decodeScreenMaterial(albedo, material1, material2);

    if (material.metallic > 0.5) {
        fragColor = encodeHDR(vec3(0.0));
        return;
    }

    vec3 sunDir = normalize(sunDirection);

    uint state = initRNG(uvec2(gl_FragCoord.xy), uvec2(ScreenSize), uint(GameTime * 20.0 * 60.0 * 240.0));

    Ray ray;
    {
        vec3 hitPos = playerPos - fract(CameraOffset) + material.normal * 0.001;
        ivec3 voxelPos = ivec3(floor(hitPos));
        ray = Ray(voxelPos, hitPos, vec3(0.0));
    }

    vec3 radiance = vec3(0.0);
    vec3 throughput = vec3(1.0);
    for (int i = 0; i < 3; i++) {
        BRDFSample samp = sampleDiffuse(material, material.normal, state);
        ray.direction = samp.direction;
        //if (i != 0) {
        throughput *= samp.throughput;
        // }
        Intersection intersection = raytrace(DepthSampler, DataSampler, ModelDataSampler, AtlasSampler, ray);

        if (!intersection.hit) {
            radiance += throughput * atmosphere(vec3(0.0, PLANET_RADIUS + 1.8, 0.0), ray.direction, sunDir, 0.5) * lightIntensity;
            break;
        }

        material = readMaterialFromAtlas(AtlasSampler, intersection.albedo.rgb, intersection.uv, intersection.tbn);
        radiance += throughput * material.emission;
        vec3 hitPos = ray.origin + ray.direction * intersection.t;

        if (dot(intersection.tbn[2], sunDir) > 0.0) {
            Ray sunRay = Ray(intersection.voxelPos, hitPos, sunDir);
            Intersection sunIntersection = raytrace(DepthSampler, DataSampler, ModelDataSampler, AtlasSampler, sunRay);
            if (!sunIntersection.hit) {
                float NdotL = clamp(dot(material.normal, sunDir), 0.0, 1.0);
                radiance += throughput * brdf(material, material.normal, -ray.direction, sunDirection, NdotL) * lightIntensity * NdotL;
            }
        }

        ray.voxelPos = intersection.voxelPos;
        ray.origin = hitPos;
    }

    fragColor = encodeHDR(radiance);
}

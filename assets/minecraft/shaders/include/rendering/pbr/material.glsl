#version 420

#if !defined(MATERIAL_GLSL)
#define MATERIAL_GLSL

#moj_import <utilities/colors.glsl>
#moj_import <utilities/octahedron_encoding.glsl>

const vec3[] HARDCODED_METALS = vec3[](
        vec3(0.52869, 0.51108, 0.49984), // Iron
        vec3(0.94202, 0.70443, 0.40355), // Gold
        vec3(0.90813, 0.91650, 0.92068), // Aluminium
        vec3(0.55315, 0.55646, 0.55843), // Chrome
        vec3(0.91530, 0.60197, 0.54991), // Copper
        vec3(0.90491, 0.92476, 0.92928), // Lead
        vec3(0.95261, 0.92577, 0.87016), // Platinum
        vec3(0.94361, 0.90240, 0.83660) // Silver
    );

const float MAX_EMISSION = 100.0;

struct Material {
    vec3 albedo;
    vec3 F0;
    float roughness;
    float metallic;
    float ambientOcclusion;
    vec3 emission;
    vec3 normal;
};

vec3 decodeNormal(mat3 tbn, vec2 normalData) {
    vec3 normal = vec3(normalData, 0.0) * 2.0 - 1.0;
    normal.z = sqrt(1.0 - dot(normal.xy, normal.xy));
    return tbn * normal;
}

vec3 decodeF0(float f0, vec3 albedo) {
    if (f0 > 237.5 / 255.0) {
        return albedo;
    }
    return f0 > 229.5 / 255.0 ? HARDCODED_METALS[int(round(f0 * 255.0)) - 230] : vec3(f0);
}

float decodeRoughness(float perceptualSmoothness) {
    return (1.0 - perceptualSmoothness) * (1.0 - perceptualSmoothness);
}

vec3 getNormal(vec4 material1) {
    return octahedronDecode(material1.xy);
}

vec3 getGeometryNormal(vec4 material1) {
    return octahedronDecode(material1.zw);
}

float getRoughness(vec4 material2) {
    return decodeRoughness(material2.r);
}

vec3 getF0(vec3 albedo, vec4 material2) {
    return decodeF0(material2.g, albedo);
}

vec3 getEmission(vec3 albedo, vec4 material2) {
    return material2.a < 1.0 ? albedo * material2.a * MAX_EMISSION : vec3(0.0);
}

float getAmbientOcclusion(vec4 material2) {
    return material2.b;
}

Material decodeScreenMaterial(vec3 albedo, vec4 material1, vec4 material2) {
    float metallic = step(229.5 / 255.0, material2.g);

    return Material(
        metallic > 0.5 ? vec3(0.0) : albedo,
        getF0(albedo, material2),
        getRoughness(material2),
        metallic,
        getAmbientOcclusion(material2),
        getEmission(albedo, material2),
        getNormal(material1)
    );
}

Material decodeLabPBR(vec3 albedo, vec4 n, vec4 s, mat3 tbn) {
    float metallic = step(229.5 / 255.0, s.g);
    return Material(
        metallic > 0.5 ? vec3(0.0) : albedo,
        decodeF0(s.g, albedo),
        decodeRoughness(s.r),
        metallic,
        n.z,
        s.a < 1.0 ? albedo * s.a * MAX_EMISSION : vec3(0.0),
        decodeNormal(tbn, n.xy)
    );
}

Material readMaterialFromAtlas(sampler2D atlas, vec3 albedo, ivec2 uv, mat3 tbn) {
    ivec2 atlasSize = textureSize(atlas, 0);
    vec4 n = texelFetch(atlas, uv + ivec2(atlasSize.x / 2, 0), 0);
    vec4 s = texelFetch(atlas, uv + ivec2(0, atlasSize.y / 2), 0);
    return decodeLabPBR(albedo, n, s, tbn);
}

#endif // MATERIAL_GLSL

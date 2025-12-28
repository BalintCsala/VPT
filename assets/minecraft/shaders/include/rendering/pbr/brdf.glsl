#version 420

#if !defined(BRDF_GLSL)
#define BRDF_GLSL

#moj_import <minecraft:math/quaternions.glsl>
#moj_import <minecraft:math/constants.glsl>
#moj_import <minecraft:rendering/pbr/material.glsl>
#moj_import <minecraft:utilities/random.glsl>

struct BRDFSample {
    vec3 direction;
    vec3 throughput;
};

float fresnelSchlick(float F0, float cosTheta) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 fresnelSchlick(vec3 F0, float cosTheta) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

// float evaluateSpecularProbability(Material material, vec3 view, vec3 halfway) {
//     float fresnel = clamp(luminance(fresnelSchlick(material.F0, max(dot(view, halfway), 0.0))), 0.0, 1.0);

//     float diffuse = luminance(material.albedo) * (1.0 - material.metallic) * (1.0 - fresnel);
//     float specular = fresnel;

//     return specular / max(specular + diffuse, EPSILON);
// }

float distributionGGX(vec3 view, float alpha) {
    float alpha2 = alpha * alpha;
    return 1.0 / (PI * alpha2 * pow(view.x * view.x / alpha2 + view.y * view.y / alpha2 + view.z * view.z, 2.0));
}

float lambdaSmith(vec3 view, float roughness) {
    return (-1.0 + sqrt(1.0 + (roughness * roughness * dot(view.xy, view.xy)) / view.z / view.z)) / 2.0;
}

// float shadowingSmith(vec3 view, float roughness) {
//     return 1.0 / (1.0 + lambdaSmith(view, roughness));
// }

float correlatedGeometrySmith(vec3 view, vec3 light, float roughness) {
    return 1.0 / (1.0 + lambdaSmith(view, roughness) + lambdaSmith(light, roughness));
}

vec3 sampleCosineWeightedHemisphere(vec3 normal, uint state) {
    vec2 v = randVec2(state);
    float angle = 2.0 * PI * v.x;
    float u = 2.0 * v.y - 1.0;

    vec3 directionOffset = vec3(sqrt(1.0 - u * u) * vec2(cos(angle), sin(angle)), u);
    return normalize(normal + directionOffset);
}

BRDFSample sampleDiffuse(Material material, vec3 normal, uint state) {
    return BRDFSample(
        sampleCosineWeightedHemisphere(normal, state),
        material.albedo
    );
}

// vec3 sampleGGXVNDF(vec3 Ve, vec2 alpha2D) {
//     vec2 u = randVec2();

// 	vec3 Vh = normalize(vec3(alpha2D.x * Ve.x, alpha2D.y * Ve.y, Ve.z));

// 	float lensq = Vh.x * Vh.x + Vh.y * Vh.y;
// 	vec3 T1 = lensq > 0.0f ? vec3(-Vh.y, Vh.x, 0.0f) * inversesqrt(lensq) : vec3(1.0f, 0.0f, 0.0f);
// 	vec3 T2 = cross(Vh, T1);

// 	float r = sqrt(u.x);
// 	float phi = 2.0 * PI * u.y;
// 	float t1 = r * cos(phi);
// 	float t2 = r * sin(phi);
// 	float s = 0.5f * (1.0f + Vh.z);
// 	t2 = mix(sqrt(1.0f - t1 * t1), t2, s);

// 	vec3 Nh = t1 * T1 + t2 * T2 + sqrt(max(0.0f, 1.0f - t1 * t1 - t2 * t2)) * Vh;

// 	return normalize(vec3(alpha2D.x * Nh.x, alpha2D.y * Nh.y, max(0.0f, Nh.z)));
// }

vec3 brdf(Material material, vec3 normal, vec3 view, vec3 light, float NdotL) {
    float NdotV = dot(normal, view);
    if (NdotV < 0.0) {
        normal = normalize(normal + dot(normal, view) * view);
    }

    vec4 q = quatRotationToZAxis(normal);
    vec3 viewTangent = quatRotate(q, view);
    vec3 lightTangent = quatRotate(q, light);
    vec3 halfwayTangent = normalize(viewTangent + lightTangent);

    NdotV = clamp(NdotV, 0.01, 1.0);
    float HdotV = clamp(dot(halfwayTangent, viewTangent), 0.01, 1.0);
    float NdotH = clamp(halfwayTangent.z, 0.01, 1.0);

    float D = distributionGGX(halfwayTangent, material.roughness);
    vec3 F = fresnelSchlick(material.F0, HdotV);
    float G = correlatedGeometrySmith(viewTangent, lightTangent, material.roughness);

    vec3 specular = D * F * G / max(4.0 * NdotV * NdotL, EPSILON);
    vec3 diffuse = material.albedo / PI * (1.0 - material.metallic);

    return diffuse + specular;
}

#endif // BRDF_GLSL


#version 420

#if !defined(MODELS_GLSL)
#define MODELS_GLSL

#moj_import <minecraft:rendering/ray.glsl>
#moj_import <minecraft:math/quaternions.glsl>
#moj_import <minecraft:utilities/float_storage.glsl>

const int PIXELS_PER_FACE = 12;

uint parseModelIdFromData(vec4 data) {
    return packUnorm4x8(vec4(data.rgb, 0.0));
}

vec2 boxIntersection(in vec3 ro, in vec3 rd, vec3 boxSize, out vec3 outNormal) {
    vec3 m = 1.0 / rd;
    vec3 n = m * ro;
    vec3 k = abs(m) * boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    if (tN > tF || tF < 0.0) return vec2(-1.0);
    outNormal = (tN >= 0.0) ? step(vec3(tN), t1) :
        step(t2, vec3(tF));
    outNormal *= -sign(rd);
    return vec2(tN, tF);
}

struct Intersection {
    bool hit;
    float t;
    ivec3 voxelPos;
    ivec2 uv;
    vec4 albedo;
    mat3 tbn;
    bool tintable;
};

Intersection noIntersection() {
    Intersection intersection;
    intersection.hit = false;
    intersection.t = -1.0;
    return intersection;
}

vec2 unpackUV(vec4 data) {
    return unpackUnorm2x16(packUnorm4x8(data)) * 65535.0;
}

Intersection intersectModel(sampler2D modelDataSampler, sampler2D atlasSampler, Ray ray, ivec3 voxelPos, uint modelId) {
    int faceCount = int(texelFetch(modelDataSampler, ivec2(0, modelId), 0).r * 255.0);
    Intersection intersection = noIntersection();
    intersection.voxelPos = voxelPos;
    for (int i = 0; i < faceCount; i++) {
        int faceOffset = PIXELS_PER_FACE * i;
        vec3 position = vec3(
                decodeFloat(texelFetch(modelDataSampler, ivec2(faceOffset + 3, modelId), 0)),
                decodeFloat(texelFetch(modelDataSampler, ivec2(faceOffset + 4, modelId), 0)),
                decodeFloat(texelFetch(modelDataSampler, ivec2(faceOffset + 5, modelId), 0))
            ) + vec3(voxelPos);
        vec3 sideX = vec3(
                decodeFloat(texelFetch(modelDataSampler, ivec2(faceOffset + 6, modelId), 0)),
                decodeFloat(texelFetch(modelDataSampler, ivec2(faceOffset + 7, modelId), 0)),
                decodeFloat(texelFetch(modelDataSampler, ivec2(faceOffset + 8, modelId), 0))
            );
        vec3 sideY = vec3(
                decodeFloat(texelFetch(modelDataSampler, ivec2(faceOffset + 9, modelId), 0)),
                decodeFloat(texelFetch(modelDataSampler, ivec2(faceOffset + 10, modelId), 0)),
                decodeFloat(texelFetch(modelDataSampler, ivec2(faceOffset + 11, modelId), 0))
            );

        vec3 tangent = normalize(sideX);
        vec3 bitangent = normalize(sideY);
        vec3 normal = cross(tangent, bitangent);
        if (dot(normal, ray.direction) >= 0.0) {
            continue;
        }

        float t = dot(position - ray.origin, normal) / dot(ray.direction, normal);
        if (t < 0.0 || (intersection.t > 0.0 && t > intersection.t)) {
            continue;
        }

        vec3 relativeHitPos = ray.origin + ray.direction * t - position;
        vec2 uv = vec2(
                dot(relativeHitPos, sideX),
                dot(relativeHitPos, sideY)
            ) / vec2(dot(sideX, sideX), dot(sideY, sideY));

        if (clamp(uv, 0.0, 1.0) != uv) {
            continue;
        }

        vec2 uvStart = unpackUV(texelFetch(modelDataSampler, ivec2(faceOffset + 1, modelId), 0));
        vec2 uvEnd = unpackUV(texelFetch(modelDataSampler, ivec2(faceOffset + 2, modelId), 0));
        ivec2 faceUV = ivec2(floor(mix(uvStart, uvEnd, uv)));

        vec4 albedo = texelFetch(atlasSampler, faceUV, 0);
        if (albedo.a < 0.1) {
            continue;
        }

        uint flags = uint(texelFetch(modelDataSampler, ivec2(faceOffset + 12, modelId), 0).r * 255.0);

        intersection.hit = true;
        intersection.t = t;
        intersection.uv = faceUV;
        intersection.albedo = albedo;
        intersection.tbn = mat3(tangent, -bitangent, normal);
        intersection.tintable = (flags & 1u) == 1u;
    }

    return intersection;
}

#endif // MODELS_GLSL

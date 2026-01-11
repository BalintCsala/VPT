#version 420

#if !defined(RAYTRACE_GLSL)
#define RAYTRACE_GLSL

#moj_import <minecraft:rendering/voxels.glsl>
#moj_import <minecraft:rendering/ray.glsl>
#moj_import <minecraft:rendering/models.glsl>
#moj_import <minecraft:math/space_conversions.glsl>

#ifndef MAX_STEPS
#define MAX_STEPS 500
#endif

struct SSRTResult {
    bool hit;
    vec3 screenPos;
};

SSRTResult raytraceSS(sampler2D depthTex, vec3 screenStart, vec3 screenEnd, mat4 projInv, float surfaceThickness, int primarySteps, int refineSteps, float jitter, bool exitOnOvershoot) {
    vec3 stepSize = (screenEnd - screenStart) / float(primarySteps);

    vec3 pos = screenStart + jitter * stepSize;
    bool found = false;
    for (int i = 0; i < primarySteps; i++) {
        if (clamp(pos.xy, 0.0, 1.0) != pos.xy) {
            return SSRTResult(false, pos - stepSize);
        }
        float depth = textureLod(depthTex, pos.xy * vec2(0.5, 1.0), 0.0).r;
        if (depth < pos.z) {
            vec3 viewPos = screenToView(projInv, pos);
            vec3 sampleViewPos = screenToView(projInv, vec3(pos.xy, depth));
            bool overshot = viewPos.z > sampleViewPos.z + surfaceThickness;
            if (overshot && exitOnOvershoot) {
                return SSRTResult(false, pos);
            } else if (!overshot) {
                found = true;
                break;
            }
        }
        pos += stepSize;
    }
    if (!found) {
        return SSRTResult(false, pos);
    }

    // Binary refinement
    stepSize *= 0.5;
    pos -= stepSize;
    // Store last correct screenPos
    vec3 screenPos = pos;
    for (int i = 0; i < refineSteps; i++) {
        stepSize *= 0.5;
        float depth = textureLod(depthTex, pos.xy * vec2(0.5, 1.0), 0.0).r;
        bool hit = false;
        if (depth < pos.z) {
            vec3 viewPos = screenToView(projInv, pos);
            vec3 sampleViewPos = screenToView(projInv, vec3(pos.xy, depth));
            hit = viewPos.z < sampleViewPos.z + surfaceThickness;
        }
        if (hit) {
            pos += stepSize;
            screenPos = pos;
        } else {
            pos -= stepSize;
        }
    }

    return SSRTResult(true, screenPos);
}

SSRTResult raytraceSSFromView(sampler2D depthTex, vec3 viewStart, vec3 viewEnd, mat4 proj, mat4 projInv, float surfaceThickness, int primarySteps, int refineSteps, float jitter, bool exitOnOvershoot) {
    vec4 clipStart = proj * vec4(viewStart, 1.0);
    vec4 clipEnd = proj * vec4(viewEnd, 1.0);
    if (clipStart.w <= 0.0 || clipEnd.w <= 0.0) {
        return SSRTResult(false, vec3(0.0));
    }
    vec3 screenStart = clipStart.xyz / clipStart.w * 0.5 + 0.5;
    vec3 screenEnd = clipEnd.xyz / clipEnd.w * 0.5 + 0.5;
    return raytraceSS(depthTex, screenStart, screenEnd, projInv, surfaceThickness, primarySteps, refineSteps, jitter, exitOnOvershoot);
}

SSRTResult raytraceSSFromPlayer(sampler2D depthTex, vec3 playerStart, vec3 playerEnd, mat4 view, mat4 proj, mat4 projInv, float surfaceThickness, int primarySteps, int refineSteps, float jitter, bool exitOnOvershoot) {
    return raytraceSSFromView(depthTex, (view * vec4(playerStart, 1.0)).xyz, (view * vec4(playerEnd, 1.0)).xyz, proj, projInv, surfaceThickness, primarySteps, refineSteps, jitter, exitOnOvershoot);
}

Intersection raytrace(sampler2D voxelSampler, sampler2D voxelDataSampler, sampler2D modelDataSampler, sampler2D atlasSampler, Ray ray) {
    vec3 stepSizes = 1.0 / abs(ray.direction);
    vec3 stepDir = sign(ray.direction);
    vec3 nextDist = (stepDir * 0.5 + 0.5 - (ray.origin - vec3(ray.voxelPos))) / ray.direction;

    ivec3 voxelPos = ray.voxelPos;
    float totalDist = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        ivec2 voxelPixelPos = getVoxelPixelPos(voxelPos);
        if (voxelPixelPos.x < 0) {
            // We reached outside of the voxel map
            break;
        }
        vec4 data = texelFetch(voxelDataSampler, voxelPixelPos, 0);
        if (data != vec4(0.0) && data != vec4(1.0)) {
            uint modelId = parseModelIdFromData(data);

            Intersection intersection = intersectModel(modelDataSampler, atlasSampler, ray, voxelPos, modelId);
            if (intersection.hit) {
                if (intersection.tintable) {
                    float voxelDepth = texelFetch(voxelSampler, voxelPixelPos, 0).r;
                    vec4 colorData = decodeColorData(voxelDepth);
                    intersection.albedo *= colorData;
                }
                return intersection;
            }
        }

        float closestDist = min(min(nextDist.x, nextDist.y), nextDist.z);
        vec3 stepAxis = vec3(equal(nextDist, vec3(closestDist)));
        voxelPos += ivec3(stepAxis * stepDir);
        nextDist += stepSizes * stepAxis - closestDist;
        totalDist += closestDist;
    }
    Intersection intersection = noIntersection();
    intersection.t = totalDist;
    return intersection;
}

#endif // RAYTRACE_GLSL

#version 420

#if !defined(RAYTRACE_GLSL)
#define RAYTRACE_GLSL

#moj_import <minecraft:rendering/voxels.glsl>
#moj_import <minecraft:rendering/ray.glsl>
#moj_import <minecraft:rendering/models.glsl>

#ifndef MAX_STEPS
#define MAX_STEPS 500
#endif

Intersection raytrace(sampler2D voxelSampler, sampler2D voxelDataSampler, sampler2D modelDataSampler, sampler2D atlasSampler, Ray ray) {
    vec3 stepSizes = 1.0 / abs(ray.direction);
    vec3 stepDir = sign(ray.direction);
    vec3 nextDist = (stepDir * 0.5 + 0.5 - (ray.origin - vec3(ray.voxelPos))) / ray.direction;

    ivec3 voxelPos = ray.voxelPos;
    for (int i = 0; i < MAX_STEPS; i++) {
        ivec2 voxelPixelPos = getVoxelPixelPos(voxelPos);
        if (voxelPixelPos.x < 0) {
            // We reached outside of the voxel map
            break;
        }
        float voxelDepth = texelFetch(voxelSampler, voxelPixelPos, 0).r;
        if (voxelDepth < 1.0) {
            vec4 data = texelFetch(voxelDataSampler, voxelPixelPos, 0);
            uint modelId = parseModelIdFromData(data);

            Intersection intersection = intersectModel(modelDataSampler, atlasSampler, ray, voxelPos, modelId);
            if (intersection.hit) {
                if (intersection.tintable) {
                    vec4 colorData = decodeColorData(voxelDepth);
                    intersection.albedo *= colorData;
                }
                return intersection;
            }
        }

        if (i == MAX_STEPS - 1) {
            // Don't waste resources on the last iteration
            break;
        }

        float closestDist = min(min(nextDist.x, nextDist.y), nextDist.z);
        vec3 stepAxis = vec3(equal(nextDist, vec3(closestDist)));
        voxelPos += ivec3(stepAxis * stepDir);
        nextDist += stepSizes * stepAxis - closestDist;
    }
    return noIntersection();
}

#endif // RAYTRACE_GLSL

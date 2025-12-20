#version 420

#if !defined(RAY_GLSL)
#define RAY_GLSL

struct Ray {
    ivec3 voxelPos;
    vec3 origin;
    vec3 direction;
};

Ray createRayFromSinglePosition(vec3 origin, vec3 direction) {
    return Ray(
        ivec3(floor(origin)),
        origin,
        direction
    );
}

#endif // RAY_GLSL
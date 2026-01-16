#version 420

#if !defined(TEMPORAL_STORAGE_GLSL)
#define TEMPORAL_STORAGE_GLSL

#moj_import <minecraft:utilities/float_storage.glsl>

vec3 getPreviousCameraPosition(sampler2D temporalSampler) {
    return vec3(
        decodeFloat(texelFetch(temporalSampler, ivec2(0, 0), 0)),
        decodeFloat(texelFetch(temporalSampler, ivec2(1, 0), 0)),
        decodeFloat(texelFetch(temporalSampler, ivec2(2, 0), 0))
    );
}

vec3 getCameraOffset(sampler2D temporalSampler, vec3 cameraPosition) {
    return cameraPosition - getPreviousCameraPosition(temporalSampler);
}

float getPreviousTime(sampler2D temporalSampler) {
    return decodeFloat(texelFetch(temporalSampler, ivec2(3, 0), 0));
}

float getDeltaTime(sampler2D temporalSampler, float time) {
    return time - getPreviousTime(temporalSampler);
}

float getPreviousExposure(sampler2D temporalSampler) {
    return decodeFloat(texelFetch(temporalSampler, ivec2(4, 0), 0));
}

mat4 getPreviousProj(sampler2D temporalSampler) {
    mat4 proj;
    for (int i = 0; i < 16; i++) {
        proj[i % 4][i / 4] = decodeFloat(texelFetch(temporalSampler, ivec2(5 + i, 0), 0));
    }
    return proj;
}

mat4 getPreviousView(sampler2D temporalSampler) {
    mat4 view;
    for (int i = 0; i < 16; i++) {
        view[i % 4][i / 4] = decodeFloat(texelFetch(temporalSampler, ivec2(21 + i, 0), 0));
    }
    return view;
}

#endif // TEMPORAL_STORAGE_GLSL

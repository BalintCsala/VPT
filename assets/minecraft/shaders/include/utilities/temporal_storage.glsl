#version 420

#if !defined(TEMPORAL_STORAGE_GLSL)
#define TEMPORAL_STORAGE_GLSL

#moj_import <minecraft:utilities/float_storage.glsl>

const int CAMERA_POSITION_X_INDEX = 0;
const int CAMERA_POSITION_Y_INDEX = 1;
const int CAMERA_POSITION_Z_INDEX = 2;
const int TIME_INDEX = 3;
const int EXPOSURE_INDEX = 4;

vec3 getPreviousCameraPosition(sampler2D temporalSampler) {
    return vec3(
        decodeFloat(texelFetch(temporalSampler, ivec2(CAMERA_POSITION_X_INDEX, 0), 0)),
        decodeFloat(texelFetch(temporalSampler, ivec2(CAMERA_POSITION_Y_INDEX, 0), 0)),
        decodeFloat(texelFetch(temporalSampler, ivec2(CAMERA_POSITION_Z_INDEX, 0), 0))
    );
}

vec3 getCameraOffset(sampler2D temporalSampler, vec3 cameraPosition) {
    return cameraPosition - getPreviousCameraPosition(temporalSampler);
}

float getPreviousTime(sampler2D temporalSampler) {
    return decodeFloat(texelFetch(temporalSampler, ivec2(TIME_INDEX, 0), 0));
}

float getDeltaTime(sampler2D temporalSampler, float time) {
    return time - getPreviousTime(temporalSampler);
}

float getPreviousExposure(sampler2D temporalSampler) {
    return decodeFloat(texelFetch(temporalSampler, ivec2(EXPOSURE_INDEX, 0), 0));
}

#endif // TEMPORAL_STORAGE_GLSL

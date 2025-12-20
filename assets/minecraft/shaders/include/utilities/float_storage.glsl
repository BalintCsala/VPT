#version 420

#if !defined(FLOAT_STORAGE_GLSL)
#define FLOAT_STORAGE_GLSL

vec4 encodeFloat(float val) {
    return unpackUnorm4x8(floatBitsToUint(val));
}

float decodeFloat(vec4 color) {
    return uintBitsToFloat(packUnorm4x8(color));
}

vec4 encodeHalf(float val) {
    vec4 result = unpackUnorm4x8(packHalf2x16(vec2(val, 0)));
    result.a = 1.0;
    return result;
}

float decodeHalf(vec4 color) {
    return unpackHalf2x16(packUnorm4x8(color)).x;
}

#endif // FLOAT_STORAGE_GLSL


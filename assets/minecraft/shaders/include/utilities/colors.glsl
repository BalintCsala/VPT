#version 420

#if !defined(COLORS_GLSL)
#define COLORS_GLSL

const float GAMMA_EXPONENT = 2.2;

vec3 srgbToLinear(vec3 color) {
    return pow(color, vec3(GAMMA_EXPONENT));
}

vec3 linearToSrgb(vec3 color) {
    return pow(color, vec3(1.0 / GAMMA_EXPONENT));
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

const float HDR_RANGE_END = 32767.0;
const vec3 HDR_RGB_SCALING = vec3(64.0, 64.0, 32.0);
const vec3 HDR_RGB_EXPONENT_OFFSETS = vec3(17 << 6, 17 << 6, 17 << 5);
const ivec3 BIT_OFFSETS = ivec3(0, 11, 22);
const ivec3 BIT_MASKS = ivec3(2047, 2047, 1023);

vec4 encodeHDR(vec3 color) {
    color = clamp(color + 0.05, 0.0, HDR_RANGE_END);
    ivec3 bits = ivec3(round(log2(color) * HDR_RGB_SCALING + HDR_RGB_EXPONENT_OFFSETS));
    bits <<= BIT_OFFSETS;
    return unpackUnorm4x8(bits.r | bits.g | bits.b);
}

vec3 decodeHDR(vec4 data) {
    uint raw = packUnorm4x8(data);
    if (raw == 0u) {
        return vec3(0.0);
    }
    ivec3 bits = (ivec3(raw) >> BIT_OFFSETS) & BIT_MASKS;
    return max(exp2((vec3(bits) - HDR_RGB_EXPONENT_OFFSETS) / HDR_RGB_SCALING) - 0.05, 0.0);
}

#endif // COLORS_GLSL

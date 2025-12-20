#version 420

#if !defined(CONSTANTS_GLSL)
#define CONSTANTS_GLSL

const float PI = 3.141592654;
const float EPSILON = 0.001;
const float E = 2.71828;

const float NANOMETER = 1e-9; // 1 nanometer in meters
const vec3 RGB_WAVELENGTHS = vec3(612.0, 549.0, 464.0) * NANOMETER;

// MASKS
const float ENTITY_MASK = 253.0 / 255.0;

// MISC
const float SUN_PATH_ANGLE = radians(20.0);

#endif // CONSTANTS_GLSL

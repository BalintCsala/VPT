#version 420

#if !defined(MATRIX_GLSL)
#define MATRIX_GLSL

mat2 mat2_rotate_z(float radians) {
    return mat2(
        cos(radians), -sin(radians),
        sin(radians), cos(radians)
    );
}

#endif // MATRIX_GLSL


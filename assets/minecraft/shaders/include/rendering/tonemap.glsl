#version 420

#if !defined(TONEMAP_GLSL)
#define TONEMAP_GLSL

#moj_import <minecraft:utilities/colors.glsl>

// By bwrensch - https://www.shadertoy.com/view/cd3XWr

vec3 agxDefaultContrastApprox(vec3 x) {
    vec3 x2 = x * x;
    vec3 x4 = x2 * x2;
    
    return + 15.5 * x4 * x2
           - 40.14 * x4 * x
           + 31.96 * x4
           - 6.868 * x2 * x
           + 0.4298 * x2
           + 0.1191 * x
           - 0.00232;
}

vec3 agx(vec3 val) {
    const mat3 agx_mat = mat3(
        0.842479062253094, 0.0423282422610123, 0.0423756549057051,
        0.0784335999999992,    0.878468636469772,    0.0784336,
        0.0792237451477643, 0.0791661274605434, 0.879142973793104
    );
        
    const float min_ev = -12.47393f;
    const float max_ev = 4.026069f;

    val = agx_mat * val;
    
    val = clamp(log2(val), min_ev, max_ev);
    val = (val - min_ev) / (max_ev - min_ev);
    
    val = agxDefaultContrastApprox(val);

    return val;
}

vec3 agxEotf(vec3 val) {
    const mat3 agx_mat_inv = mat3(
        1.19687900512017, -0.0528968517574562, -0.0529716355144438,
        -0.0980208811401368, 1.15190312990417, -0.0980434501171241,
        -0.0990297440797205, -0.0989611768448433, 1.15107367264116
    );
        
    val = agx_mat_inv * val;

    return val;
}

vec3 tonemap(vec3 color) {
    color = agx(color * 0.5);
    float luma = luminance(color);
    color *= vec3(1.0, 0.98, 0.95);
    color = pow(color, vec3(1.5));
    float saturation = 1.3;
    color = luma + saturation * (color - luma);
    return agxEotf(color);
}

// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/

vec3 ACESFilm(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
}

#endif // TONEMAP_GLSL
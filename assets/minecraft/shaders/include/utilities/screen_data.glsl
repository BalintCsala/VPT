#version 420

#if !defined(SCREEN_DATA_GLSL)
#define SCREEN_DATA_GLSL

#moj_import <minecraft:math/constants.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:utilities/float_storage.glsl>

struct ScreenData {
    #if defined(PROJ_MAT) || defined(PROJ_MAT_INV)
    mat4 projMat;
    #endif
    #ifdef PROJ_MAT_INV
    mat4 projMatInv;
    #endif
    #if defined(VIEW_MAT) || defined(VIEW_MAT_INV) || defined(SUN_DIRECTION)
    mat4 viewMat;
    #endif
    #if defined(VIEW_MAT_INV) || defined(SUN_DIRECTION)
    mat4 viewMatInv;
    #endif
    #ifdef SUN_DIRECTION
    vec3 sunDirection;
    #endif
    #ifdef SUN_INFO
    float sunInfo;
    #endif
};

ScreenData parseScreenData(sampler2D screenSampler) {
    ivec2 startPixel = ivec2(ScreenSize.x / 2.0, ScreenSize.y - 1);
    ScreenData screenData;
    #if defined(PROJ_MAT) || defined(PROJ_MAT_INV)
    for (int i = 0; i < 16; i++) {
        screenData.projMat[i % 4][i / 4] = decodeFloat(texelFetch(screenSampler, startPixel + ivec2(3 + 16 + i, 0), 0));
    }
    #endif
    #ifdef PROJ_MAT_INV
    screenData.projMatInv = inverse(screenData.projMat);
    #endif
    #if defined(VIEW_MAT) || defined(VIEW_MAT_INV)
    for (int i = 0; i < 16; i++) {
        screenData.viewMat[i % 4][i / 4] = decodeFloat(texelFetch(screenSampler, startPixel + ivec2(3 + i, 0), 0));
    }
    #endif
    #ifdef VIEW_MAT_INV
    screenData.viewMatInv = inverse(screenData.viewMat);
    #endif
    #ifdef SUN_DIRECTION
    for (int i = 0; i < 3; i++) {
        screenData.sunDirection[i] = decodeHalf(texelFetch(screenSampler, startPixel + ivec2(3 + 16 + 16 + i, 0), 0));
    }
    screenData.sunDirection = mat3(screenData.viewMatInv) * screenData.sunDirection;

    mat2 rotMat = mat2(
            cos(SUN_PATH_ANGLE), sin(SUN_PATH_ANGLE),
            -sin(SUN_PATH_ANGLE), cos(SUN_PATH_ANGLE)
        );
    screenData.sunDirection.zy = rotMat * screenData.sunDirection.zy;
    #endif
    #ifdef SUN_INFO
    vec4 sunInfoData = texelFetch(screenSampler, startPixel + ivec2(3 + 16 + 16 + 3, 0), 0);
    screenData.sunInfo = sunInfoData.r * 2.0 + sunInfoData.g;
    #endif
    return screenData;
}

#endif // SCREEN_DATA_GLSL

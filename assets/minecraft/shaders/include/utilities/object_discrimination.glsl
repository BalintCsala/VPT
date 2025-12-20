#version 420

#if !defined(UTILS_GLSL)
#define UTILS_GLSL

#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:fog.glsl>

bool isGUI() {
    // Check if ProjMat is ortho
    return ProjMat[3][3] > 0.5;
}

bool isHand() {
    return abs(ProjMat[3][2] - (-0.10005)) < 0.00001;
}

#endif // UTILS_GLSL
#version 420

#if !defined(SPLITSCREEN_GLSL)
#define SPLITSCREEN_GLSL

#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:utilities/object_discrimination.glsl>

vec4 applyClipPosSplitScreen(vec4 clipPos) {
    if (!isHand() && !isGUI()) {
        clipPos.x = clipPos.x * 0.5 - clipPos.w * 0.5;
    }
    return clipPos;
}

bool shouldDiscardSplitScreen(vec2 fragCoord) {
    return !isHand() && !isGUI() && fragCoord.x > ScreenSize.x * 0.5;
}

#endif // SPLITSCREEN_GLSL
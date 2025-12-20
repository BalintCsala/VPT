#version 420

#if !defined(CONVERSIONS_GLSL)
#define CONVERSIONS_GLSL

vec3 screenToView(mat4 projMatInv, vec3 screenPos) {
    vec4 tmp = projMatInv * vec4(screenPos * 2.0 - 1.0, 1.0);
    return tmp.xyz / tmp.w;
}

vec3 screenToPlayer(mat4 viewMatInv, mat4 projMatInv, vec3 screenPos) {
    return (viewMatInv * vec4(screenToView(projMatInv, screenPos), 1.0)).xyz;
}

vec4 playerToClip(mat4 projMat, mat4 viewMat, vec3 playerPos) {
    return projMat * viewMat * vec4(playerPos, 1.0);
}

vec3 viewToScreen(mat4 projMat, vec3 view) {
    vec4 clip = projMat * vec4(view, 1.0);
    return clip.xyz / clip.w * 0.5 + 0.5;
}
#endif // CONVERSIONS_GLSL

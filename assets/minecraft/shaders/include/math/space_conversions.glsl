#version 420

#if !defined(CONVERSIONS_GLSL)
#define CONVERSIONS_GLSL

vec3 screenToView(mat4 projInv, vec3 screenPos) {
    vec4 tmp = projInv * vec4(screenPos * 2.0 - 1.0, 1.0);
    return tmp.xyz / tmp.w;
}

vec3 screenToPlayer(mat4 viewInv, mat4 projInv, vec3 screenPos) {
    return (viewInv * vec4(screenToView(projInv, screenPos), 1.0)).xyz;
}

vec4 playerToClip(mat4 proj, mat4 view, vec3 playerPos) {
    return proj * view * vec4(playerPos, 1.0);
}

vec3 viewToScreen(mat4 proj, vec3 view) {
    vec4 clip = proj * vec4(view, 1.0);
    return clip.xyz / clip.w * 0.5 + 0.5;
}

vec3 playerToScreen(mat4 proj, mat4 view, vec3 player) {
    return viewToScreen(proj, (view * vec4(player, 1.0)).xyz);
}

#endif // CONVERSIONS_GLSL

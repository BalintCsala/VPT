#version 420

#moj_import <minecraft:utilities/text.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:globals.glsl>

out vec4 fragColor;

void main() {
    if (distance(ColorModulator.rgb, vec3(0.0)) < 0.01) {
        discard;
    }
    if (gl_FragCoord.y > ScreenSize.y - 32.0) {
        fragColor = vec4(0, 0, 0, 1);
        return;
    }
    TEXT(ivec2(0, 0), ivec2(gl_FragCoord.xy / 3), (_Y, _O, _U, _SPACE, _N, _E, _E, _D, _SPACE, _T, _O, _SPACE, _E, _N, _A, _B, _L, _E, _SPACE, _I, _M, _P, _R, _O, _V, _E, _D, _SPACE, _T, _R, _A, _N, _S, _P, _A, _R, _E, _N, _C, _Y, _SPACE, _I, _N, _SPACE, _T, _H, _E, _SPACE, _V, _I, _D, _E, _O, _SPACE, _S, _E, _T, _T, _I, _N, _G, _S, _EXCLM, _SPACE, _SPACE, _SPACE), fragColor, vec4(1), vec4(0));
}

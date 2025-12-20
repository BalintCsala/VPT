#version 420

#moj_import <minecraft:utilities/screen_data.glsl>

#ifndef SAMPLER_NAME
#error "You must define SAMPLER_NAME"
#endif

#ifdef PROJ_MAT
out mat4 projMat;
#endif
#ifdef PROJ_MAT_INV
out mat4 projMatInv;
#endif
#ifdef VIEW_MAT
out mat4 viewMat;
#endif
#ifdef VIEW_MAT_INV
out mat4 viewMatInv;
#endif
#ifdef SUN_DIRECTION
out vec3 sunDirection;
#endif
#ifdef SUN_INFO
out float sunInfo;
#endif

out vec2 texCoord;

const vec2[] OFFSETS = vec2[](
        vec2(-1.0, 1.0),
        vec2(1.0, -1.0),
        vec2(1.0, 1.0)
    );

void main() {
    ScreenData screenData = parseScreenData(SAMPLER_NAME);
    #ifdef PROJ_MAT
    projMat = screenData.projMat;
    #endif
    #ifdef PROJ_MAT_INV
    projMatInv = screenData.projMatInv;
    #endif
    #ifdef VIEW_MAT
    viewMat = screenData.viewMat;
    #endif
    #ifdef VIEW_MAT_INV
    viewMatInv = screenData.viewMatInv;
    #endif
    #ifdef SUN_DIRECTION
    sunDirection = screenData.sunDirection;
    #endif
    #ifdef SUN_INFO
    sunInfo = screenData.sunInfo;
    #endif

    #ifdef EXTRA
    EXTRA();
    #endif

    float scale = 1.0;
    #ifdef SCALE
    scale = SCALE;
    #endif

    gl_Position = vec4(OFFSETS[gl_VertexID] * scale * 2.0 - 1.0, 0.0, 1.0);
    texCoord = (gl_Position.xy * 0.5 + 0.5) / scale;
}

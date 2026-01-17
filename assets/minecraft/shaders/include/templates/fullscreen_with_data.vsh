#version 420

#moj_import <minecraft:utilities/screen_data.glsl>

#ifndef SAMPLER_NAME
#error "You must define SAMPLER_NAME"
#endif

void extra();

#ifdef PROJ
flat out mat4 proj;
#endif
#ifdef PROJ_INV
flat out mat4 projInv;
#endif
#ifdef VIEW
flat out mat4 view;
#endif
#ifdef VIEW_INV
flat out mat4 viewInv;
#endif
#ifdef SUN_DIRECTION
flat out vec3 sunDirection;
#endif
#ifdef SUN_INFO
flat out float sunInfo;
#endif

out vec2 texCoord;

const vec2[] OFFSETS = vec2[](
        vec2(-1.0, 1.0),
        vec2(1.0, -1.0),
        vec2(1.0, 1.0)
    );

void main() {
    ScreenData screenData = parseScreenData(SAMPLER_NAME);
    #ifdef PROJ
    proj = screenData.proj;
    #endif
    #ifdef PROJ_INV
    projInv = screenData.projInv;
    #endif
    #ifdef VIEW
    view = screenData.view;
    #endif
    #ifdef VIEW_INV
    viewInv = screenData.viewInv;
    #endif
    #ifdef SUN_DIRECTION
    sunDirection = screenData.sunDirection;
    #endif
    #ifdef SUN_INFO
    sunInfo = screenData.sunInfo;
    #endif

    #ifdef EXTRA
    extra();
    #endif

    vec2 scale = vec2(1.0);
    #ifdef SCALE
    scale = vec2(SCALE);
    #endif

    gl_Position = vec4(OFFSETS[gl_VertexID] * scale * 2.0 - 1.0, 0.0, 1.0);
    texCoord = (gl_Position.xy * 0.5 + 0.5) / scale;
}

#version 420

#moj_import <minecraft:utilities/temporal_storage.glsl>
#moj_import <minecraft:globals.glsl>

uniform sampler2D DataSampler;
uniform sampler2D TemporalSampler;

out vec3 cameraOffset;
out mat4 prevProjMat;
out mat4 prevViewMat;

void extra();

#define EXTRA extra

#define SAMPLER_NAME DataSampler
#define PROJ_MAT
#define PROJ_MAT_INV
#define VIEW_MAT
#define VIEW_MAT_INV

#define SCALE 0.25

#moj_import <minecraft:templates/fullscreen_with_data.vsh>

void extra() {
    cameraOffset = getCameraOffset(TemporalSampler, vec3(CameraBlockPos) - fract(CameraOffset));
    prevProjMat = getPreviousProj(TemporalSampler);
    prevViewMat = getPreviousView(TemporalSampler);
}

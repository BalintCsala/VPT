#version 420

#moj_import <minecraft:utilities/temporal_storage.glsl>
#moj_import <minecraft:globals.glsl>

uniform sampler2D DataSampler;
uniform sampler2D TemporalSampler;

flat out vec3 cameraOffset;
flat out mat4 prevProj;
flat out mat4 prevView;

#define EXTRA

#define SAMPLER_NAME DataSampler
#define PROJ
#define PROJ_INV
#define VIEW
#define VIEW_INV

#define SCALE 0.25

#moj_import <minecraft:templates/fullscreen_with_data.vsh>

void extra() {
    cameraOffset = getCameraOffset(TemporalSampler, vec3(CameraBlockPos) - fract(CameraOffset));
    prevProj = getPreviousProj(TemporalSampler);
    prevView = getPreviousView(TemporalSampler);
}

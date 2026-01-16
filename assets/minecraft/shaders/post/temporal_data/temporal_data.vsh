#version 420

uniform sampler2D DataSampler;

out float exposure;

void extra();

#define EXTRA extra

#define SAMPLER_NAME DataSampler
#define PROJ_MAT
#define VIEW_MAT

#moj_import <minecraft:templates/fullscreen_with_data.vsh>

void extra() {
    // TODO: exposure
    exposure = 0.0;
}

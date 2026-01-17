#version 420

uniform sampler2D DataSampler;

flat out float exposure;

#define EXTRA

#define SAMPLER_NAME DataSampler
#define PROJ
#define VIEW

#moj_import <minecraft:templates/fullscreen_with_data.vsh>

void extra() {
    // TODO: exposure
    exposure = 0.0;
}

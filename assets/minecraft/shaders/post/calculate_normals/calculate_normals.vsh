#version 420

uniform sampler2D DataSampler;

#define SAMPLER_NAME DataSampler
#define PROJ_INV
#define VIEW_INV
#moj_import <minecraft:templates/fullscreen_with_data.vsh>

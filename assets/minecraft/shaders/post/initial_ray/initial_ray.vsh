#version 420

uniform sampler2D DataSampler;

#define SAMPLER_NAME DataSampler
#define PROJ_MAT
#define PROJ_MAT_INV
#define VIEW_MAT
#define VIEW_MAT_INV
#moj_import <minecraft:templates/fullscreen_with_data.vsh>

#version 420

uniform sampler2D DataSampler;

#define SAMPLER_NAME DataSampler
#define PROJ
#define PROJ_INV
#define VIEW
#define VIEW_INV
#define SUN_DIRECTION
#define SCALE 0.5

#moj_import <minecraft:templates/fullscreen_with_data.vsh>

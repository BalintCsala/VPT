#version 420

#moj_import <minecraft:rendering/atmosphere.glsl>

uniform sampler2D DataSampler;

out vec3 lightIntensity;

void extra();

#define EXTRA extra

#define SAMPLER_NAME DataSampler
#define PROJ_MAT
#define PROJ_MAT_INV
#define VIEW_MAT
#define VIEW_MAT_INV
#define SUN_DIRECTION
#moj_import <minecraft:templates/fullscreen_with_data.vsh>

void extra() {
    vec3 sunDir = normalize(sunDirection);
    lightIntensity = atmosphere(vec3(0.0, PLANET_RADIUS + 1.8, 0.0), sunDir, sunDir, 0.5);
}

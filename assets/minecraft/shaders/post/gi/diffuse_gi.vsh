#version 420

#moj_import <minecraft:rendering/atmosphere.glsl>

uniform sampler2D DataSampler;

flat out vec3 lightIntensity;

#define EXTRA

#define SAMPLER_NAME DataSampler
#define PROJ
#define PROJ_INV
#define VIEW
#define VIEW_INV
#define SUN_DIRECTION

#define SCALE 0.5

#moj_import <minecraft:templates/fullscreen_with_data.vsh>

void extra() {
    vec3 sunDir = normalize(sunDirection);
    lightIntensity = atmosphere(vec3(0.0, PLANET_RADIUS + 1.8, 0.0), sunDir, sunDir, 0.5);
}

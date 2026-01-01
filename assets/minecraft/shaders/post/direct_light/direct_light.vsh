#version 420

#moj_import <minecraft:rendering/atmosphere.glsl>

#define PROJ_MAT
#define PROJ_MAT_INV
#define VIEW_MAT
#define VIEW_MAT_INV
#define MODEL_OFFSET
#define SUN_DIRECTION
#define SUN_INFO
#moj_import <minecraft:utilities/screen_data.glsl>

uniform sampler2D DataSampler;

out mat4 projMat;
out mat4 projMatInv;
out mat4 viewMat;
out mat4 viewMatInv;
out vec3 sunDirection;
out float sunInfo;
out vec3 lightIntensity;

out vec2 texCoord;

void main() {
    ScreenData screenData = parseScreenData(DataSampler);
    projMat = screenData.projMat;
    projMatInv = screenData.projMatInv;
    viewMat = screenData.viewMat;
    viewMatInv = screenData.viewMatInv;
    sunDirection = screenData.sunDirection;
    sunInfo = screenData.sunInfo;
    vec3 sunDir = normalize(sunDirection);
    lightIntensity = atmosphere(vec3(0.0, PLANET_RADIUS + 1.8, 0.0), sunDir, sunDir, 0.5);

    vec2 uv = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);
    vec4 pos = vec4(uv * vec2(2, 2) + vec2(-1, -1), 0, 1);

    gl_Position = pos;
    texCoord = uv;
}

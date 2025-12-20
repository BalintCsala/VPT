#version 420

#moj_import <minecraft:light.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:splitscreen.glsl>
#moj_import <minecraft:utilities/object_discrimination.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

out vec4 vertexColor;
out vec4 vertexColorBack;
out vec4 overlayColor;
out vec2 texCoord0;

void main() {
    gl_Position = applyClipPosSplitScreen(ProjMat * ModelViewMat * vec4(Position, 1.0));

    if (isGUI()) {
        vec2 light = minecraft_compute_light(Light0_Direction, Light1_Direction, Normal);
        vertexColor = minecraft_mix_light_separate(light, Color);
        vertexColorBack = minecraft_mix_light_separate(-light, Color);
    } else {
        vertexColor = Color;
    }
    overlayColor = texelFetch(Sampler1, UV1, 0);

    texCoord0 = UV0;
    #ifdef APPLY_TEXTURE_MATRIX
    texCoord0 = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
    #endif
}

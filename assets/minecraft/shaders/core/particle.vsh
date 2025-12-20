#version 420

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:splitscreen.glsl>

in vec3 Position;
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;

out vec2 texCoord0;
out vec4 vertexColor;

void main() {
    gl_Position = applyClipPosSplitScreen(ProjMat * ModelViewMat * vec4(Position, 1.0));

    texCoord0 = UV0;
    vertexColor = Color;
}

#version 420

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:splitscreen.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;

out vec4 vertexColor;
out vec2 texCoord0;

void main() {
    gl_Position = applyClipPosSplitScreen(ProjMat * ModelViewMat * vec4(Position, 1.0));

    vertexColor = Color;
    texCoord0 = UV0;
}

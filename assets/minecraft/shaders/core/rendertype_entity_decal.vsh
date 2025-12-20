#version 420

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:splitscreen.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler1;

out vec4 vertexColor;
out vec4 overlayColor;
out vec2 texCoord0;

void main() {
    gl_Position = applyClipPosSplitScreen(ProjMat * ModelViewMat * vec4(Position, 1.0));

    vertexColor = Color;
    overlayColor = texelFetch(Sampler1, UV1, 0);
    texCoord0 = UV0;
}

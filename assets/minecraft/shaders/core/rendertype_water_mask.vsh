#version 420

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:splitscreen.glsl>

in vec3 Position;

void main() {
    gl_Position = applyClipPosSplitScreen(ProjMat * ModelViewMat * vec4(Position, 1.0));
}

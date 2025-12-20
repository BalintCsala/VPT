#version 420

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:splitscreen.glsl>

in vec3 Position;
in vec4 Color;

out vec4 vertexColor;

void main() {
    vec4 viewPos = ModelViewMat * vec4(Position, 1.0);
    if (viewPos.z > -138.0) {
        // Horizon
        gl_Position = vec4(-1.0);
        return;
    }
    gl_Position = applyClipPosSplitScreen(ProjMat * viewPos);

    vertexColor = Color;
}

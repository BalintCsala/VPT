#version 420

#moj_import <minecraft:splitscreen.glsl>

flat in vec4 vertexColor;

out vec4 fragColor;

void main() {
    if (shouldDiscardSplitScreen(gl_FragCoord.xy)) {
        discard;
    }
    fragColor = vertexColor;
}

#version 420

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:splitscreen.glsl>

in vec4 vertexColor;

out vec4 fragColor;

void main() {
    if (shouldDiscardSplitScreen(gl_FragCoord.xy)) {
        discard;
    }
    fragColor = vertexColor * ColorModulator;
    if (fragColor.a < 0.1) {
        discard;
    }
}

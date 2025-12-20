#version 420

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:splitscreen.glsl>

uniform sampler2D Sampler0;

in vec4 vertexColor;
in vec2 texCoord0;

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

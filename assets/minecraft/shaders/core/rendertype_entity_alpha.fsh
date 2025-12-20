#version 420

#moj_import <minecraft:splitscreen.glsl>

uniform sampler2D Sampler0;

in vec4 vertexColor;
in vec2 texCoord0;
in vec2 texCoord1;
in vec2 texCoord2;

out vec4 fragColor;

void main() {
    if (shouldDiscardSplitScreen(gl_FragCoord.xy)) {
        discard;
    }
    fragColor = texture(Sampler0, texCoord0);
    if (fragColor.a < vertexColor.a) {
        discard;
    }
}

#version 420

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:splitscreen.glsl>

uniform sampler2D Sampler0;

in vec2 texCoord0;

out vec4 fragColor;

void main() {
    if (shouldDiscardSplitScreen(gl_FragCoord.xy)) {
        discard;
    }
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a == 0.0) {
        discard;
    }
    fragColor = color * ColorModulator;
}

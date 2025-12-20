#version 420

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:splitscreen.glsl>

uniform sampler2D Sampler0;

in vec4 vertexColor;
in vec4 overlayColor;
in vec2 texCoord0;

out vec4 fragColor;

void main() {
    if (shouldDiscardSplitScreen(gl_FragCoord.xy)) {
        discard;
    }
    fragColor = texture(Sampler0, texCoord0);
    if (fragColor.a < 0.1) {
        discard;
    }
    fragColor = vec4(mix(overlayColor.rgb, fragColor.rgb, overlayColor.a), 1.0) * vertexColor * ColorModulator;
}

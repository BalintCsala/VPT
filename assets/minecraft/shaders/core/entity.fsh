#version 420

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:splitscreen.glsl>
#moj_import <minecraft:math/constants.glsl>
#moj_import <minecraft:utilities/object_discrimination.glsl>

uniform sampler2D Sampler0;

in vec4 overlayColor;

in vec4 vertexColor;
in vec4 vertexColorBack;

in vec2 texCoord0;

out vec4 fragColor;

void main() {
    if (shouldDiscardSplitScreen(gl_FragCoord.xy)) {
        discard;
    }
    fragColor = texture(Sampler0, texCoord0);
    #ifdef ALPHA_CUTOUT
    if (fragColor.a < ALPHA_CUTOUT) {
        discard;
    }
    #endif

    #ifdef PER_FACE_LIGHTING
    if (isGUI()) {
        fragColor *= (gl_FrontFacing ? vertexColor : vertexColorBack) * ColorModulator;
    } else {
        fragColor *= vertexColor * ColorModulator;
    }
    #else
    fragColor *= vertexColor * ColorModulator;
    #endif

    #ifndef NO_OVERLAY
    fragColor.rgb = mix(overlayColor.rgb, fragColor.rgb, overlayColor.a);
    #endif

    #ifdef ALPHA_CUTOUT
    if (!isGUI() && !isHand()) {
        fragColor.a = ENTITY_MASK;
    }
    #endif
}

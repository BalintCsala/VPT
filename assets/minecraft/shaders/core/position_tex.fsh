#version 420

#moj_import <minecraft:splitscreen.glsl>
#moj_import <minecraft:utilities/float_storage.glsl>

// Can't moj_import in things used during startup, when resource packs don't exist.
// This is a copy of dynamicimports.glsl
layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
    mat4 TextureMat;
};

uniform sampler2D Sampler0;

in vec2 texCoord0;
in vec4 vertexColor;
in float sun;
in float endSky;
in vec4 vertex1;
in vec4 vertex2;

out vec4 fragColor;

void main() {
    if (sun > 0.5) {
        int index = int(gl_FragCoord.x) - int(ScreenSize.x / 2.0 + 16.0 + 16.0);
        if (index == 3) {
            // Which "sun" are we drawing?
            fragColor = vec4(floor(sun) * 0.5, fract(sun), 0.0, 1.0);
            return;
        }
        vec3 sunDirection = normalize(vertex1.xyz / vertex1.w + vertex2.xyz / vertex2.w);
        fragColor = encodeHalf(sunDirection[index]);
        return;
    }
    if (endSky > 0.5 && gl_FragCoord.x > ScreenSize.x / 2.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    } else if (shouldDiscardSplitScreen(gl_FragCoord.xy)) {
        discard;
    }
    vec4 color = texture(Sampler0, texCoord0) * vertexColor;
    if (color.a == 0.0) {
        discard;
    }
    fragColor = color * ColorModulator;
}

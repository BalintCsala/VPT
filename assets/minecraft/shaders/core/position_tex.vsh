#version 420

#moj_import <minecraft:splitscreen.glsl>

// Can't moj_import in things used during startup, when resource packs don't exist.
// This is a copy of dynamicimports.glsl and projection.glsl
layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
    mat4 TextureMat;
};

ivec2[] VERTEX_OFFSETS = ivec2[](
        ivec2(0, 0),
        ivec2(1, 0),
        ivec2(1, 1),
        ivec2(0, 1)
    );

uniform sampler2D Sampler0;

in vec3 Position;
in vec2 UV0;
in vec4 Color;

out vec2 texCoord0;
out vec4 vertexColor;

out float sun;
out float endSky;
out vec4 vertex1;
out vec4 vertex2;

void main() {
    texCoord0 = UV0;
    vertexColor = Color;
    sun = 0.0;
    endSky = 0.0;
    vertex1 = vec4(0.0);
    vertex2 = vec4(0.0);

    vec4 color = texture(Sampler0, UV0);
    bool isSun = distance(color, vec4(1.0, 0.0, 1.0, 123.0 / 255.0)) < 0.005;
    bool isEndFlash = abs(color.a - 117.0 / 255.0) < 0.5 / 255.0;
    bool isEndSky = abs(color.a - 116.0 / 255.0) < 0.5 / 255.0;

    if (isEndSky) {
        endSky = 1.0;
    }

    gl_Position = applyClipPosSplitScreen(ProjMat * ModelViewMat * vec4(Position, 1.0));

    if (isSun || isEndFlash) {
        // Sun or end flash
        vec3 vertex = (ModelViewMat * vec4(Position, 1.0)).xyz;
        if (isSun) {
            sun = 1.0;
        } else {
            sun = 2.0 + vertexColor.a * 254.0 / 255.0;
        }

        ivec2 vertexOffset = ivec2(ScreenSize.x / 2.0, ScreenSize.y - 1.0) + ivec2(16 + 16, 0) + VERTEX_OFFSETS[gl_VertexID] * ivec2(4, 1);

        gl_Position = vec4(
                vec2(vertexOffset) / ScreenSize * 2.0 - 1.0,
                0.0,
                1.0
            );

        if (gl_VertexID % 4 == 0) {
            vertex1 = vec4(vertex, 1.0);
        } else if (gl_VertexID % 4 == 2) {
            vertex2 = vec4(vertex, 1.0);
        }
    }
}

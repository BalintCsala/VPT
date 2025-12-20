#version 420

#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:splitscreen.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:rendering/voxels.glsl>
#moj_import <minecraft:chunksection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;

out vec4 vertexColor;
out vec2 texCoord0;
out float isVoxel;

vec4 minecraft_sample_lightmap(sampler2D lightMap, ivec2 uv) {
    return texture(lightMap, clamp(uv / 256.0, vec2(0.5 / 16.0), vec2(15.5 / 16.0)));
}

ivec2[] VERTEX_OFFSETS = ivec2[](
        ivec2(0, 0),
        ivec2(1, 0),
        ivec2(1, 1),
        ivec2(0, 1)
    );

void main() {
    texCoord0 = UV0;

    vec4 color = texture(Sampler0, UV0);
    isVoxel = 0.0;
    if (isMarker(color)) {
        if (Normal.y > 0.5) {
            // Voxel
            isVoxel = 1.0;
            vec3 position = floor(ChunkPosition - CameraBlockPos + CameraOffset) + Position;
            ivec3 voxelPos = ivec3(floor(position));
            ivec2 pixelPos = getVoxelPixelPos(voxelPos);
            if (pixelPos.x < 0) {
                // Outside of the range
                gl_Position = vec4(-1.0);
                return;
            }
            gl_Position = vec4((pixelPos + VERTEX_OFFSETS[gl_VertexID % 4]) / ScreenSize * 2.0 - 1.0, 0.0, 1.0);
            gl_Position.z = encodeColorData(Color) * 2.0 - 1.0;
        } else {
            // Data passthrough face
            isVoxel = 2.0;
            gl_Position = vec4(
                    (vec2(ScreenSize.x / 2.0, ScreenSize.y - 1.0) + VERTEX_OFFSETS[gl_VertexID % 4] * vec2(64.0, 1.0)) / ScreenSize * 2.0 - 1.0,
                    0.0, 1.0
                );
        }
        return;
    }
    vec3 pos = ChunkPosition - CameraBlockPos + CameraOffset + Position;
    gl_Position = applyClipPosSplitScreen(ProjMat * ModelViewMat * vec4(pos, 1.0));

    vertexColor = Color;
}

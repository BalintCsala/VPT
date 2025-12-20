#version 420

#if !defined(VOXELS_GLSL)
#define VOXELS_GLSL

#moj_import <minecraft:globals.glsl>

const vec4 VOXEL_MARKER_COLOR = vec4(255.0, 0.0, 255.0, 123.0) / 255.0;

bool isMarker(vec4 color) {
    vec4 diff = color - VOXEL_MARKER_COLOR;
    return abs(dot(diff, diff)) < 0.001;
}

int getVoxelRange() {
    float totalArea = (ScreenSize.x / 2.0) * (ScreenSize.y - 1.0);
    return int(pow(totalArea, 1.0 / 3.0));
}

// Returns a negative value if the position isn't inside the voxelized area
ivec2 getVoxelPixelPos(ivec3 position) {
    int range = getVoxelRange();
    int halfRange = range / 2;
    if (position.x < -halfRange || position.y < -halfRange || position.z < -halfRange || position.x >= halfRange || position.y >= halfRange || position.z >= halfRange) {
        return ivec2(-1);
    }
    ivec3 unsignedPosition = position + halfRange;
    int voxelIndex = unsignedPosition.x + range * (unsignedPosition.y + range * unsignedPosition.z);
    int halfScreenWidth = int(ScreenSize.x / 2.0);
    return ivec2(halfScreenWidth, 0) + ivec2(voxelIndex % halfScreenWidth, voxelIndex / halfScreenWidth);
}

float encodeColorData(vec4 color) {
    uvec4 colorDataComponents = uvec4(floor(color * 127.0));
    uint colorData = colorDataComponents.r | (colorDataComponents.g << 7) | (colorDataComponents.b << 14);
    colorData = colorData << 3u;
    return float(colorData) / float((1 << 24) - 1);
}

vec4 decodeColorData(float depth) {
    uint colorData = uint(depth * float((1 << 24) - 1)) >> 3u;
    uvec4 colorDataComponents = uvec4(colorData & 127u, (colorData >> 7u) & 127u, (colorData >> 14u) & 127u, 127u);
    return vec4(colorDataComponents) / 127.0;
}

#endif // VOXELS_GLSL
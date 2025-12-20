#version 420

#moj_import <minecraft:templates/initial_ray.fsh>

vec4 hit(vec2 texCoord, float depth, Intersection intersection) {
    ivec2 atlasSize = textureSize(AtlasSampler, 0);
    return texelFetch(AtlasSampler, intersection.uv + ivec2(0, atlasSize.y / 2), 0);
}

vec4 miss(vec2 texCoord, float depth) {
    return vec4(0.0, 0.04, 0.0, 0.0);
}

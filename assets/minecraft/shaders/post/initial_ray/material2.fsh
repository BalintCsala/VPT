#version 420

#moj_import <minecraft:templates/initial_ray.fsh>

vec4 hit(vec2 texCoord, float depth, Intersection intersection) {
    ivec2 atlasSize = textureSize(AtlasSampler, 0);
    vec4 normalData = texelFetch(AtlasSampler, intersection.uv + ivec2(atlasSize.x / 2, 0), 0);
    vec4 specularData = texelFetch(AtlasSampler, intersection.uv + ivec2(0, atlasSize.y / 2), 0);
    return vec4(specularData.r, specularData.g, normalData.b, specularData.a);
}

vec4 miss(vec2 texCoord, float depth) {
    return vec4(0.0, 0.04, 1.0, 0.0);
}

#version 420

uniform sampler2D NormalSampler;

#moj_import <minecraft:templates/initial_ray.fsh>

vec4 hit(vec2 texCoord, float depth, Intersection intersection) {
    ivec2 atlasSize = textureSize(AtlasSampler, 0);
    vec4 data = texelFetch(AtlasSampler, intersection.uv + ivec2(atlasSize.x / 2, 0), 0);
    vec3 normal = decodeNormal(intersection.tbn, data.rg);
    return vec4(normal * 0.5 + 0.5, data.b);
}

vec4 miss(vec2 texCoord, float depth) {
    return vec4(textureLod(NormalSampler, texCoord, 0.0).rgb, 0.0);
}

#version 420

uniform sampler2D MainDepthSampler;

#moj_import <minecraft:templates/initial_ray.fsh>
#moj_import <minecraft:utilities/octahedron_encoding.glsl>

vec4 hit(vec2 texCoord, float depth, Intersection intersection) {
    ivec2 atlasSize = textureSize(AtlasSampler, 0);
    vec4 data = texelFetch(AtlasSampler, intersection.uv + ivec2(atlasSize.x / 2, 0), 0);
    vec3 normal = decodeNormal(intersection.tbn, data.rg);
    return vec4(
        octahedronEncode(normal),
        octahedronEncode(intersection.tbn[2])
    );
}

vec4 miss(vec2 texCoord, float depth) {
    ivec2 pixel = ivec2(gl_FragCoord.xy * vec2(0.5, 1.0));
    vec2 pixelSize = 1.0 / ScreenSize;

    float depthCenter = texelFetch(MainDepthSampler, pixel, 0).r;
    float depthLeft = texelFetchOffset(MainDepthSampler, pixel, 0, ivec2(-1, 0)).r;
    float depthRight = texelFetchOffset(MainDepthSampler, pixel, 0, ivec2(1, 0)).r;
    float depthBottom = texelFetchOffset(MainDepthSampler, pixel, 0, ivec2(0, -1)).r;
    float depthTop = texelFetchOffset(MainDepthSampler, pixel, 0, ivec2(0, 1)).r;

    float normalSign = 1.0;

    float horizontalDepth;
    vec2 horizontalTexCoord;
    if (abs(depthLeft - depthCenter) < abs(depthRight - depthCenter)) {
        horizontalDepth = depthLeft;
        horizontalTexCoord = texCoord + vec2(-2.0, 0.0) * pixelSize;
        normalSign *= -1.0;
    } else {
        horizontalDepth = depthRight;
        horizontalTexCoord = texCoord + vec2(2.0, 0.0) * pixelSize;
    }

    float verticalDepth;
    vec2 verticalTexCoord;
    if (abs(depthBottom - depthCenter) < abs(depthTop - depthCenter)) {
        verticalDepth = depthBottom;
        verticalTexCoord = texCoord + vec2(0.0, -1.0) * pixelSize;
        normalSign *= -1.0;
    } else {
        verticalDepth = depthTop;
        verticalTexCoord = texCoord + vec2(0.0, 1.0) * pixelSize;
    }

    vec3 centerPos = screenToPlayer(viewMatInv, projMatInv, vec3(texCoord, depthCenter));
    vec3 horizontalPos = screenToPlayer(viewMatInv, projMatInv, vec3(horizontalTexCoord, horizontalDepth));
    vec3 verticalPos = screenToPlayer(viewMatInv, projMatInv, vec3(verticalTexCoord, verticalDepth));
    vec3 normal = normalize(cross(horizontalPos - centerPos, verticalPos - centerPos)) * normalSign;

    vec2 encoded = octahedronEncode(normal);
    return vec4(encoded, encoded);
}

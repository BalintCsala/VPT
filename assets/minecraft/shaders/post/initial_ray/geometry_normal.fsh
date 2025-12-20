#version 420

#moj_import <minecraft:templates/initial_ray.fsh>

uniform sampler2D DepthSampler;

vec4 hit(vec2 texCoord, float depth, Intersection intersection) {
    return vec4(intersection.tbn[2] * 0.5 + 0.5, 1.0);
}

vec4 miss(vec2 texCoord, float depth) {
    ivec2 pixel = ivec2(gl_FragCoord.xy * vec2(0.5, 1.0));
    vec2 pixelSize = 1.0 / ScreenSize;

    float depthCenter = texelFetch(DepthSampler, pixel, 0).r;
    float depthLeft = texelFetchOffset(DepthSampler, pixel, 0, ivec2(-1, 0)).r;
    float depthRight = texelFetchOffset(DepthSampler, pixel, 0, ivec2(1, 0)).r;
    float depthBottom = texelFetchOffset(DepthSampler, pixel, 0, ivec2(0, -1)).r;
    float depthTop = texelFetchOffset(DepthSampler, pixel, 0, ivec2(0, 1)).r;

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
    normal = normalize(step(0.5, normal) - step(0.5, -normal));

    return vec4(normal * 0.5 + 0.5, 1.0);
}

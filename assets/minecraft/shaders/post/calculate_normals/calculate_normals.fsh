#version 420

#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:math/space_conversions.glsl>

uniform sampler2D DepthSampler;

in vec2 texCoord;
in mat4 projMatInv;
in mat4 viewMatInv;

out vec4 fragColor;

const float NEAR = 0.05;

void main() {
    ivec2 pixel = ivec2(gl_FragCoord.xy * vec2(0.5, 1.0));

    vec2 pixelSize = 1.0 / ScreenSize;
    vec2 scaledTexCoord = texCoord * vec2(0.5, 1.0);

    float depthCenter = textureLod(DepthSampler, scaledTexCoord, 0.0).r;
    if (depthCenter == 1.0) {
        fragColor = vec4(0.0);
        return;
    }
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
    fragColor = vec4(normal * 0.5 + 0.5, 1.0);
}

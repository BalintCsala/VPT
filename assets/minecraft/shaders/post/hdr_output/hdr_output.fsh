#version 420

#moj_import <minecraft:rendering/tonemap.glsl>
#moj_import <minecraft:utilities/colors.glsl>

uniform sampler2D MainSampler;
uniform sampler2D DirectSampler;
uniform sampler2D DiffuseGISampler;
uniform sampler2D BloomSampler;

in vec2 texCoord;

out vec4 fragColor;

void main() {
    vec3 albedo = srgbToLinear(textureLod(MainSampler, texCoord * vec2(0.5, 1.0), 0.0).rgb);
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    vec3 radiance = decodeHDR(texelFetch(DirectSampler, pixel, 0));

    vec2 fractional = fract(gl_FragCoord.xy / 4.0);
    vec3 diffuseGI = mix(
            mix(
                decodeHDR(texelFetchOffset(DiffuseGISampler, pixel / 4, 0, ivec2(0, 0))),
                decodeHDR(texelFetchOffset(DiffuseGISampler, pixel / 4, 0, ivec2(1, 0))),
                fractional.x
            ),
            mix(
                decodeHDR(texelFetchOffset(DiffuseGISampler, pixel / 4, 0, ivec2(0, 1))),
                decodeHDR(texelFetchOffset(DiffuseGISampler, pixel / 4, 0, ivec2(1, 1))),
                fractional.x
            ),
            fractional.y
        );

    vec3 bloom = decodeHDR(texelFetch(BloomSampler, pixel, 0));
    vec3 result = tonemap(radiance + diffuseGI * albedo + bloom * 0.01);
    result = linearToSrgb(result);
    fragColor = vec4(result, 1.0);
}

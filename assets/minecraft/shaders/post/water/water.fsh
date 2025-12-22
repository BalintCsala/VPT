#version 420

#moj_import <minecraft:utilities/random.glsl>
#moj_import <minecraft:utilities/colors.glsl>
#moj_import <minecraft:math/space_conversions.glsl>
#moj_import <minecraft:rendering/pbr/brdf.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:rendering/atmosphere.glsl>
#moj_import <minecraft:math/constants.glsl>
#moj_import <minecraft:rendering/raytrace.glsl>
#moj_import <minecraft:rendering/pbr/material.glsl>

const vec3 WATER_EXTINCTION_COEFF = vec3(1.2340e-8, 2.1344e-9, 9.724e-10) * 4.0 * PI / RGB_WAVELENGTHS;
const float WATER_IOR = 1.333;
const float REFRACTION_FUDGE_FACTOR = 0.7;
const int SSRT_STEPS = 8;
const float SSRT_THICKNESS = 2.0;

uniform sampler2D AtlasSampler;
uniform sampler2D ModelDataSampler;
uniform sampler2D DataSampler;
uniform sampler2D SolidSampler;
uniform sampler2D DepthSampler;
uniform sampler2D TranslucentSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D Material1Sampler;
uniform sampler2D Material2Sampler;
uniform sampler2D TranslucentMaterial1Sampler;
uniform sampler2D TranslucentMaterial2Sampler;

in mat4 projMat;
in mat4 projMatInv;
in mat4 viewMat;
in mat4 viewMatInv;
in vec3 sunDirection;
in vec2 texCoord;
in vec3 lightIntensity;

out vec4 fragColor;

const vec4[] WAVE_PARAMS = vec4[](
        vec4(-0.40265, 0.91535, 400.00000, 0.00020),
        vec4(-0.96752, 0.25278, 240.00000, 0.00040),
        vec4(-0.44129, 0.89737, 144.00000, 0.00080),
        vec4(0.79777, 0.60296, 86.40000, 0.00160),
        vec4(0.77260, 0.63490, 51.84000, 0.00320),
        vec4(0.10668, 0.99429, 31.10400, 0.00640),
        vec4(-0.96931, 0.24583, 18.66240, 0.01280),
        vec4(-0.52662, 0.85010, 11.19744, 0.02560),
        vec4(0.43712, 0.89940, 6.71846, 0.05120),
        vec4(-0.84470, 0.53524, 4.03108, 0.10240),
        vec4(0.93952, 0.34250, 2.41865, 0.20480),
        vec4(0.34952, 0.93693, 1.45119, 0.40960),
        vec4(0.39672, 0.91794, 0.87071, 0.81920),
        vec4(0.66205, 0.74946, 0.52243, 1.63840),
        vec4(0.41432, 0.91013, 0.31346, 3.27680));

const int WAVE_COMPONENTS = 6;

void main() {
    gl_FragDepth = 0.1;
    uint randState = initRNG(uvec2(gl_FragCoord.xy), uvec2(ScreenSize), uint(GameTime * 20.0 * 60.0 * 300.0));

    vec2 scaledTexCoord = texCoord * vec2(0.5, 1.0);

    float solidDepth = textureLod(DepthSampler, scaledTexCoord, 0.0).r;
    float translucentDepth = textureLod(TranslucentDepthSampler, scaledTexCoord, 0.0).r;

    if (translucentDepth == solidDepth) {
        // Solid
        fragColor = textureLod(SolidSampler, texCoord, 0.0);
        return;
    }

    vec4 translucentColor = textureLod(TranslucentSampler, scaledTexCoord, 0.0);
    vec4 diff = translucentColor - vec4(0.0, 0.0, 0.0, 1.0);
    if (dot(diff, diff) > 0.001) {
        // TODO: Stained glass
        fragColor = encodeHDR(vec3(0.0));
        return;
    }

    vec3 cameraPosition = vec3(CameraBlockPos) - fract(CameraOffset);
    vec3 fragmentPos = screenToPlayer(viewMatInv, projMatInv, vec3(texCoord, translucentDepth));
    vec3 solidPos = screenToPlayer(viewMatInv, projMatInv, vec3(texCoord, solidDepth));
    vec3 worldPos = fragmentPos + cameraPosition;

    bool topFace = false;
    vec4 material1 = textureLod(TranslucentMaterial1Sampler, texCoord, 0.0);
    vec3 normal = getNormal(material1);
    if (normal.y > 0.95) {
        topFace = true;

        float weight = 0.0;
        float time = GameTime * 2400.0 * 3.0;
        vec2 deriv = vec2(0.0);
        float startOffset = min(log2(length(fragmentPos.xz) + 1.0) * 2.0, float(WAVE_PARAMS.length() - WAVE_COMPONENTS));

        uint waveRand = 123457;
        for (int i = 0; i < WAVE_COMPONENTS; i++) {
            vec4 params = WAVE_PARAMS[i + int(startOffset)];
            vec2 dir = params.xy;
            float frequency = params.z;
            float scale = params.w;
            float dist = dot(worldPos.xz, dir);

            float timeVal = mod(dist * frequency + time / 4.0, 2.0 * PI);
            vec2 componentDeriv = exp(sin(timeVal)) * cos(timeVal) * scale * frequency * dir;

            if (i == 0) {
                scale *= 1.0 - fract(startOffset);
                componentDeriv *= 1.0 - fract(startOffset);
            } else if (i == WAVE_COMPONENTS - 1) {
                scale *= fract(startOffset);
                componentDeriv *= fract(startOffset);
            }

            deriv += componentDeriv;
            weight += scale;
        }
        deriv *= 5.0 / 16.0;

        normal = cross(vec3(0, deriv.y, 1), vec3(1, deriv.x, 0));
        vec3 viewDir = normalize(fragmentPos);
        normal -= max(dot(normal, viewDir), 0.0) * viewDir;
        normal = normalize(normal);
    }

    float distInWater = distance(fragmentPos, solidPos);
    vec3 viewDir = (fragmentPos - solidPos) / distInWater;

    vec3 sunDir = normalize(sunDirection);

    vec3 refractedDir = refract(-viewDir, normal, 1.0 / WATER_IOR);
    refractedDir = normalize(mix(-viewDir, refractedDir, REFRACTION_FUDGE_FACTOR));
    Ray ray = createRayFromSinglePosition(fragmentPos - fract(CameraOffset), refractedDir);

    vec4 startClipPos = playerToClip(projMat, viewMat, fragmentPos);
    vec3 startScreenPos = startClipPos.xyz / startClipPos.w * 0.5 + 0.5;

    Intersection intersection = raytrace(DepthSampler, DataSampler, ModelDataSampler, AtlasSampler, ray);

    float dist;
    if (intersection.hit) {
        dist = intersection.t;
    } else {
        dist = distInWater;
    }

    vec3 endPos = fragmentPos + refractedDir * dist;
    vec4 endClipPos = playerToClip(projMat, viewMat, endPos);
    bool endPosInside = clamp(endClipPos.xyz, -endClipPos.w, endClipPos.w) == endClipPos.xyz;
    vec3 endScreenPos = endClipPos.xyz / endClipPos.w * 0.5 + 0.5;

    bool foundHit = false;
    Material material;
    if (endPosInside) {
        vec3 rtStep = (endScreenPos - startScreenPos) / float(SSRT_STEPS - 1);
        vec3 pos = startScreenPos + rtStep * randFloat(randState);

        for (int i = 0; i < SSRT_STEPS; i++) {
            float depth = textureLod(DepthSampler, pos.xy * vec2(0.5, 1.0), 0.0).r;
            float translucentDepth = textureLod(TranslucentDepthSampler, pos.xy * vec2(0.5, 1.0), 0.0).r;
            if (translucentDepth == depth) {
                // Ray went outside of the water area, can't do anything from here
                break;
            }

            if (depth < pos.z) {
                vec4 baseColor = textureLod(DataSampler, pos.xy * vec2(0.5, 1.0), 0.0);
                if (abs(baseColor.a - ENTITY_MASK) < 0.5 / 255.0) {
                    vec3 viewPos = screenToView(projMatInv, vec3(pos.xy, depth));
                    viewPos.z -= SSRT_THICKNESS;
                    vec3 screenPos = viewToScreen(projMat, viewPos);
                    if (pos.z < screenPos.z) {
                        endPos = (viewMatInv * vec4(viewPos, 1.0)).xyz;
                        dist = distance(fragmentPos, endPos);
                        foundHit = true;
                        material = decodeScreenMaterial(
                                srgbToLinear(baseColor.rgb),
                                textureLod(Material1Sampler, pos.xy, 0.0),
                                textureLod(Material2Sampler, pos.xy, 0.0)
                            );
                        break;
                    }
                }
            }

            pos += rtStep;
        }
    }

    if (!foundHit) {
        if (intersection.hit) {
            material = readMaterialFromAtlas(AtlasSampler, srgbToLinear(intersection.albedo.rgb), intersection.uv, intersection.tbn);
        } else if (endPosInside && abs(1.0 / (1.005 - endScreenPos.z) - 1.0 / (1.005 - textureLod(DepthSampler, endScreenPos.xy * vec2(0.5, 1.0), 0.0).r)) < 15.0) {
            material = decodeScreenMaterial(
                    srgbToLinear(textureLod(DataSampler, endScreenPos.xy * vec2(0.5, 1.0), 0.0).rgb),
                    textureLod(Material1Sampler, endScreenPos.xy, 0.0),
                    textureLod(Material2Sampler, endScreenPos.xy, 0.0)
                );
        } else {
            // Nothing to fall back to
            material = Material(vec3(0.0), vec3(0.0), 1.0, 0.0, 0.0, vec3(0, 0, 0), vec3(0, 0, 0));
        }
    }

    vec3 radiance = vec3(0, 0, 0);
    if (solidDepth == 1.0) {
        // Sky behind water
        radiance = decodeHDR(textureLod(SolidSampler, texCoord, 0.0));
        dist = min(dist, 1.4);
    } else {
        radiance = material.emission + 0.05 * material.albedo * (1.0 - material.metallic);
        float NdotL = dot(material.normal, sunDir);
        if (NdotL > 0.001) {
            Ray sunRay = Ray(intersection.voxelPos, endPos - fract(CameraOffset), sunDir);
            Intersection sunIntersection = raytrace(DepthSampler, DataSampler, ModelDataSampler, AtlasSampler, sunRay);
            if (!sunIntersection.hit) {
                radiance += brdf(material, material.normal, -refractedDir, sunDir, NdotL) * lightIntensity * NdotL;
            }
        }
    }

    if (!topFace) {
        // Limit absorption for vertical faces as these are normally on "waterfalls"
        dist = min(dist, 1.4);
    }

    if (dist < 0.0) {
        fragColor = encodeHDR(vec3(1, 0, 0));
        return;
    }
    radiance *= exp(-dist * WATER_EXTINCTION_COEFF);

    Material waterMaterial = Material(
            vec3(0.0),
            vec3(0.02),
            0.0015,
            0.0,
            0.0,
            vec3(0.0),
            normal
        );

    {
        float NdotL = dot(waterMaterial.normal, sunDir);
        if (NdotL > 0.001) {
            vec3 specular = brdf(waterMaterial, normal, viewDir, sunDir, clamp(dot(sunDir, normal), 0.0, 1.0)) * NdotL * lightIntensity;
            radiance = mix(radiance, specular, fresnelSchlick(vec3(0.02), clamp(dot(normal, viewDir), 0.001, 0.999)).x);
        }
    }

    fragColor = encodeHDR(radiance);
}

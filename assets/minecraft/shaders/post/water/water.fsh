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
#moj_import <minecraft:rendering/atmosphere.glsl>
#moj_import <minecraft:hacks.glsl>

const vec3 WATER_EXTINCTION_COEFF = 1.0 - vec3(0.38, 0.58, 0.48);
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

flat in mat4 proj;
flat in mat4 projInv;
flat in mat4 view;
flat in mat4 viewInv;
flat in vec3 sunDirection;
flat in vec3 lightIntensity;

in vec2 texCoord;

out vec4 fragColor;

struct Wave {
    vec2 direction;
    float waveNumber;
    float frequency;
    float amplitude;
};

const Wave[] WAVE_PARAMS = Wave[](
        Wave(vec2(0.792330, -0.610093), 335.255081, 57.344538, 0.000073),
        Wave(vec2(0.727436, 0.686176), 286.067669, 52.972488, 0.000086),
        Wave(vec2(0.763461, 0.645854), 94.134635, 30.384437, 0.000261),
        Wave(vec2(0.796133, -0.605121), 56.492615, 23.541001, 0.000434),
        Wave(vec2(0.508631, -0.860985), 45.083855, 21.027727, 0.000544),
        Wave(vec2(0.803054, -0.595906), 34.078153, 18.278833, 0.000720),
        Wave(vec2(0.942411, 0.334458), 16.419563, 12.686798, 0.001495),
        Wave(vec2(0.978580, 0.205865), 13.543189, 11.524409, 0.001812),
        Wave(vec2(0.953498, 0.301399), 13.521125, 11.513937, 0.001815),
        Wave(vec2(0.962634, -0.270807), 13.201664, 11.377801, 0.001859),
        Wave(vec2(0.903494, 0.428601), 8.589489, 9.178687, 0.002857),
        Wave(vec2(0.998913, 0.046621), 7.609370, 8.639380, 0.003225),
        Wave(vec2(0.779681, -0.626177), 2.246977, 4.691445, 0.010923),
        Wave(vec2(0.611150, 0.791515), 1.307998, 3.581416, 0.018764),
        Wave(vec2(0.840992, -0.541047), 1.074261, 3.241076, 0.022847),
        Wave(vec2(0.725323, 0.688408), 0.971099, 3.083997, 0.025274),
        Wave(vec2(0.721998, -0.691895), 0.957780, 3.063053, 0.025626),
        Wave(vec2(0.917864, 0.396894), 0.725192, 2.665118, 0.033844),
        Wave(vec2(0.945143, 0.326656), 0.677090, 2.576106, 0.036249),
        Wave(vec2(0.956561, -0.291532), 0.538919, 2.298599, 0.045542),
        Wave(vec2(0.530888, -0.847442), 0.380782, 1.932079, 0.064456),
        Wave(vec2(0.840253, 0.542194), 0.362883, 1.884956, 0.067635),
        Wave(vec2(0.633772, -0.773520), 0.295529, 1.701696, 0.083050),
        Wave(vec2(0.974190, -0.225728), 0.193314, 1.377065, 0.126963),
        Wave(vec2(0.985255, 0.171093), 0.150017, 1.209513, 0.163606),
        Wave(vec2(0.591065, -0.806624), 0.037396, 0.602139, 0.656314),
        Wave(vec2(0.904077, -0.427370), 0.024485, 0.486947, 1.002397)
    );
const int WAVE_COMPONENTS = 6;

void main() {
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
    vec3 fragmentPos = screenToPlayer(viewInv, projInv, vec3(texCoord, translucentDepth));
    vec3 solidPos = screenToPlayer(viewInv, projInv, vec3(texCoord, solidDepth));
    vec3 worldPos = fragmentPos + cameraPosition;

    float effectScaleFactor = log2(length(fragmentPos) + 1.0);

    bool topFace = false;
    vec4 material1 = textureLod(TranslucentMaterial1Sampler, texCoord, 0.0);
    vec3 normal = getNormal(material1);
    if (normal.y > 0.95) {
        topFace = true;

        float time = GameTime * 1200.0;
        vec2 deriv = vec2(0.0);
        float startOffset = clamp(effectScaleFactor * 3.5 - 2.0, 0.0, float(WAVE_PARAMS.length() - WAVE_COMPONENTS));

        uint waveRand = 123457;
        for (int i = 0; i < WAVE_COMPONENTS; i++) {
            Wave params = WAVE_PARAMS[i + int(startOffset)];

            if (i == 0) {
                params.amplitude *= 1.0 - fract(startOffset);
            } else if (i == WAVE_COMPONENTS - 1) {
                params.amplitude *= fract(startOffset);
            }

            float inner = dot(worldPos.xz, params.direction) * params.waveNumber - time * params.frequency;
            float sinTerm = sin(inner) + 1.0;
            float cosTerm = cos(inner);
            vec2 componentDeriv = 0.5 * params.amplitude * params.waveNumber * sinTerm * cosTerm * params.direction;

            deriv += componentDeriv;
        }

        normal = cross(vec3(0, deriv.y, 1), vec3(1, deriv.x, 0));
        vec3 viewDir = normalize(fragmentPos);
        normal -= max(dot(normal, viewDir), 0.05) * viewDir;
        normal = normalize(normal);
    }

    float distInWater = distance(fragmentPos, solidPos);
    vec3 viewDir = (fragmentPos - solidPos) / distInWater;

    vec3 sunDir = normalize(sunDirection);

    vec3 radiance = vec3(0, 0, 0);
    float fresnel = fresnelSchlick(0.02, clamp(dot(normal, viewDir), 0.0, 1.0));

    vec3 refractedDir = refract(-viewDir, normal, 1.0 / WATER_IOR);
    refractedDir = normalize(mix(-viewDir, refractedDir, REFRACTION_FUDGE_FACTOR));

    if (fresnel < 0.8) {
        Ray ray = createRayFromSinglePosition(fragmentPos - fract(CameraOffset), refractedDir);

        vec4 startClipPos = playerToClip(proj, view, fragmentPos);
        vec3 startScreenPos = startClipPos.xyz / startClipPos.w * 0.5 + 0.5;

        Intersection intersection = raytrace(DepthSampler, DataSampler, ModelDataSampler, AtlasSampler, ray);

        float dist;
        if (intersection.hit) {
            dist = intersection.t;
        } else {
            dist = distInWater;
        }

        if (!topFace) {
            // Limit absorption for vertical faces as these are normally "waterfalls"
            dist = min(dist, 1.4);
        }

        vec3 endPos = fragmentPos + refractedDir * dist;
        vec4 endClipPos = playerToClip(proj, view, endPos);
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
                        vec3 viewPos = screenToView(projInv, vec3(pos.xy, depth));
                        viewPos.z -= SSRT_THICKNESS;
                        vec3 screenPos = viewToScreen(proj, viewPos);
                        if (pos.z < screenPos.z) {
                            endPos = (viewInv * vec4(viewPos, 1.0)).xyz;
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

        vec3 throughput = exp(-dist * WATER_EXTINCTION_COEFF);

        if (solidDepth == 1.0) {
            // Sky behind water
            radiance += throughput * decodeHDR(textureLod(SolidSampler, texCoord, 0.0)) * (1.0 - fresnel);
            dist = min(dist, 1.4);
        } else {
            radiance += throughput * (material.emission + lightIntensity * AMBIENT_FACTOR * material.albedo * (1.0 - material.metallic) * material.ambientOcclusion) * (1.0 - fresnel);
            float NdotL = dot(material.normal, sunDir);
            if (NdotL > 0.001) {
                Ray sunRay = Ray(intersection.voxelPos, endPos - fract(CameraOffset), sunDir);
                Intersection sunIntersection = raytrace(DepthSampler, DataSampler, ModelDataSampler, AtlasSampler, sunRay);
                if (!sunIntersection.hit) {
                    radiance += throughput * brdf(material, material.normal, -refractedDir, sunDir, NdotL) * lightIntensity * NdotL * (1.0 - fresnel);
                }
            }
        }
    }

    Material waterMaterial = Material(
            vec3(0.0),
            vec3(0.02),
            effectScaleFactor * 0.001 + 0.002,
            0.0,
            0.0,
            vec3(0.0),
            normal
        );

    {
        vec3 reflectedDir = reflect(-viewDir, normal);

        Ray ray = createRayFromSinglePosition(fragmentPos - fract(CameraOffset), reflectedDir);
        Intersection intersection = raytrace(DepthSampler, DataSampler, ModelDataSampler, AtlasSampler, ray);

        if (intersection.hit) {
            Material material = readMaterialFromAtlas(AtlasSampler, srgbToLinear(intersection.albedo.rgb), intersection.uv, intersection.tbn);
            float NdotL = clamp(dot(material.normal, sunDir), 0.0, 1.0);
            radiance += (
                lightIntensity * AMBIENT_FACTOR * material.albedo * (1.0 - material.metallic) * material.ambientOcclusion +
                    material.emission +
                    brdf(material, material.normal, -ray.direction, sunDir, NdotL) * lightIntensity * NdotL
                ) * fresnel;
        } else {
            vec3 startPos = fragmentPos + reflectedDir * intersection.t;
            vec3 endPos = startPos + reflectedDir * 32.0;
            SSRTResult result = raytraceSSFromPlayer(DepthSampler, startPos, endPos, view, proj, projInv, 8.0, 8, 4, randFloat(randState), false);
            if (result.hit) {
                radiance += decodeHDR(textureLod(SolidSampler, result.screenPos.xy, 0.0)) * fresnel;
            } else {
                vec3 sky = atmosphere(ray.origin + vec3(0.0, PLANET_RADIUS, 0.0), ray.direction, sunDir, 0.5);
                radiance += sky * fresnel;
            }
        }

        float NdotL = dot(waterMaterial.normal, sunDir);
        if (NdotL > 0.001) {
            vec3 specular = brdf(waterMaterial, normal, viewDir, sunDir, clamp(dot(sunDir, normal), 0.0, 1.0)) * NdotL * lightIntensity;
            radiance += specular * fresnel;
        }
    }

    fragColor = encodeHDR(radiance);
}

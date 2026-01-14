#if !defined(ATMOSPHERE_GLSL)
#define ATMOSPHERE_GLSL

#moj_import <minecraft:math/constants.glsl>

const vec3 LIGHT_INTENSITY = vec3(1.0) * 3.5;

const vec3 RAYLEIGH_SCATTERING_COEFF = vec3(5.5e-6, 13.0e-6, 22.4e-6);
const float MIE_SCATTERING_COEFF = 2.1e-5;
const vec3 OZONE_ABSORPTION = vec3(2.04e-5, 4.97e-5, 1.95e-6);

const float PLANET_RADIUS = 6371.0e3;
const float ATMOSPHERE_RADIUS = PLANET_RADIUS + 100.0e3;
const int MAIN_STEPS = 16;
const int SECONDARY_STEPS = 5;
const float COS_SUN_ANGULAR_RADIUS = cos(radians(0.53));
const float SUN_EDGE_SIZE = 0.00003;

const vec3 ATMOSPHERE_CAMERA_POSITION = vec3(0.0, PLANET_RADIUS, 0.0);

vec2 sphereIntersect(in vec3 origin, in vec3 direction, float radius) {
    float b = dot(origin, direction);
    float c = dot(origin, origin) - radius * radius;
    float disc = b * b - c;
    if (disc < 0.0) {
        return vec2(-1.0);
    }
    disc = sqrt(disc);
    return vec2(-b - disc, -b + disc);
}

float calculateRayleighPhase(float cosTheta) {
    return 3.0 / (16.0 * PI) * (1.0 + cosTheta * cosTheta);
}

float calculateMiePhase(float cosTheta) {
    const float G = 0.76;
    return 3.0 / (8.0 * PI) * (1.0 - G * G) * (cosTheta * cosTheta + 1.0) / pow(1.0 + G * G - 2.0 * cosTheta * G, 1.5) / (2.0 + G * G);
}

vec3 densityRatio(float height) {
    const float RAYLEIGH_SCALE = 8500.0;
    const float MIE_SCALE = 1200.0;
    const float OZONE_CENTER = 25000.0;
    const float OZONE_RADIUS = 15000.0;
    vec3 density = vec3(
            exp(-height / vec2(RAYLEIGH_SCALE, MIE_SCALE)),
            0.0
        );
    density.z = 1.0 / (pow((30.0e3 - height) / 4.0e3, 2.0) + 1.0) * density.x;
    return density;
}

vec3 calculateOpticalDepthToSun(vec3 origin, vec3 direction) {
    float distToAtmosphere = sphereIntersect(origin, direction, ATMOSPHERE_RADIUS).y;
    float distToPlanet = sphereIntersect(origin, direction, PLANET_RADIUS).x;
    float dist = (distToAtmosphere > 0.0 && distToPlanet < distToAtmosphere) ? distToAtmosphere : distToPlanet;
    float stepSize = distToAtmosphere / float(SECONDARY_STEPS - 1);
    vec3 rayStep = direction * stepSize;
    vec3 pos = origin + rayStep * 0.5;

    vec3 opticalDepth = vec3(0.0);
    for (int j = 0; j < SECONDARY_STEPS; j++) {
        float height = length(pos) - PLANET_RADIUS;
        opticalDepth += densityRatio(height);

        pos += rayStep;
    }
    return opticalDepth * stepSize;
}

vec3 atmosphere(vec3 origin, vec3 direction, vec3 sunDir, float jitter) {
    vec3 pos = origin;
    float distToAtmosphere = sphereIntersect(origin, direction, ATMOSPHERE_RADIUS).y;
    float distToPlanet = sphereIntersect(origin, direction, PLANET_RADIUS).x;
    float dist = distToPlanet < 0.0 ? distToAtmosphere : distToPlanet;

    float stepSize = dist / float(MAIN_STEPS - 1);
    vec3 rayStep = direction * stepSize;
    pos += rayStep * (jitter * 0.03 + 0.485);

    float cosTheta = dot(direction, sunDir);
    float rayleighPhase = calculateRayleighPhase(cosTheta);
    float miePhase = calculateMiePhase(cosTheta);

    vec3 rayleighTransmittance = vec3(0.0);
    vec3 mieTransmittance = vec3(0.0);
    vec3 opticalDepthToCamera = vec3(0.0);
    for (int i = 0; i < MAIN_STEPS; i++) {
        float height = length(pos) - PLANET_RADIUS;
        vec3 segmentOpticalDepth = densityRatio(height) * stepSize;
        opticalDepthToCamera += segmentOpticalDepth;

        vec3 opticalDepthToSun = calculateOpticalDepthToSun(pos, sunDir);
        vec3 totalOpticalDepth = opticalDepthToSun + opticalDepthToCamera;

        vec3 attenuation = exp(-totalOpticalDepth.x * RAYLEIGH_SCATTERING_COEFF - totalOpticalDepth.y * MIE_SCATTERING_COEFF - totalOpticalDepth.z * OZONE_ABSORPTION);

        rayleighTransmittance += segmentOpticalDepth.x * attenuation;
        mieTransmittance += segmentOpticalDepth.y * attenuation;

        pos += rayStep;
    }

    vec3 background = smoothstep(COS_SUN_ANGULAR_RADIUS - SUN_EDGE_SIZE, COS_SUN_ANGULAR_RADIUS + SUN_EDGE_SIZE, dot(direction, sunDir)) * LIGHT_INTENSITY;
    vec3 transmittance = exp(-opticalDepthToCamera.x * RAYLEIGH_SCATTERING_COEFF - opticalDepthToCamera.y * MIE_SCATTERING_COEFF - opticalDepthToCamera.z * OZONE_ABSORPTION);

    return smoothstep(0.0, 0.05, direction.y) * ((
        RAYLEIGH_SCATTERING_COEFF * rayleighPhase * rayleighTransmittance +
            MIE_SCATTERING_COEFF * miePhase * mieTransmittance
        ) * LIGHT_INTENSITY + transmittance * background);
}

#endif // ATMOSPHERE_GLSL

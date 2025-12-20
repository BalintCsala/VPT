#version 420

#if !defined(RANDOM_GLSL)
#define RANDOM_GLSL

uint rand(inout uint state) {
    uint newState = state * uint(747796405) + uint(2891336453);
	uint word = ((newState >> ((newState >> uint(28)) + uint(4))) ^ newState) * uint(277803737);
    state = (word >> uint(22)) ^ word;
    return state;
}

float randFloat(inout uint state) {
    return float(rand(state) & uvec3(0x7fffffffU)) / float(0x7fffffff);
}

vec2 randVec2(inout uint state) {
    return vec2(randFloat(state), randFloat(state));
}

vec3 randVec3(inout uint state) {
    return vec3(randFloat(state), randFloat(state), randFloat(state));
}

vec4 randVec4(inout uint state) {
    return vec4(randFloat(state), randFloat(state), randFloat(state), randFloat(state));
}

uint initRNG(uvec2 pixel, uvec2 resolution, uint frame) {
    uint state = frame;
    state = (pixel.x + pixel.y * resolution.x) ^ rand(state);
    return rand(state);
}

#endif // RANDOM_GLSL
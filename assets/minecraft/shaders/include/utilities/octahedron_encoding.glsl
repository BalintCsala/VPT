#version 420

#if !defined(OCTAHEDRON_ENCODING_GLSL)
#define OCTAHEDRON_ENCODING_GLSL

// Adapted from https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
vec2 octahedronEncode(vec3 n) {
    n /= dot(abs(n), vec3(1.0));
    float t = clamp(-n.z, 0.0, 1.0);
    n.xy += vec2(n.x >= 0.0 ? t : -t, n.y >= 0.0 ? t : -t);
    return n.xy * 0.5 + 0.5;
}
 
vec3 octahedronDecode(vec2 f) {
    f = f * 2.0 - 1.0;
    vec3 n = vec3(f.x, f.y, 1.0 - dot(abs(f), vec2(1.0)));
    float t = clamp(-n.z, 0.0, 1.0);
    n.xy += vec2(n.x >= 0.0 ? -t : t, n.y >= 0.0 ? -t : t);
    return normalize(n);
}

#endif // OCTAHEDRON_ENCODING_GLSL
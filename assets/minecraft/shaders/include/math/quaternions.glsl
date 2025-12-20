#version 420

#if !defined(QUATERNIONS_GLSL)
#define QUATERNIONS_GLSL

vec4 quatAxisAngle(vec3 axis, float angle) {
    return vec4(
        axis * sin(angle / 2.0),
        cos(angle / 2.0)
    );
}

vec4 quatMultiply(vec4 q1, vec4 q2) {
    return vec4(
        cross(q1.xyz, q2.xyz) + q1.xyz * q2.w + q2.xyz * q1.w,
        q1.w * q2.w - dot(q1.xyz, q2.xyz)
    );
}

vec3 quatRotate(vec4 q, vec3 p) {
    vec4 qInv = vec4(-q.xyz, q.w);
    vec4 first = quatMultiply(q, vec4(p, 0.0));
    return cross(first.xyz, qInv.xyz) + first.w * qInv.xyz + first.xyz * qInv.w;
}

vec4 quatRotationToZAxis(vec3 vec) {
	// Handle special case when input is exact or near opposite of (0, 0, 1)
	if (vec.z < -0.99999) return vec4(1.0, 0.0, 0.0, 0.0);
	return normalize(vec4(vec.y, -vec.x, 0.0, 1.0 + vec.z));
}

#endif // QUATERNIONS_GLSL
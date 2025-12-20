#version 400

#moj_import <minecraft:utilities/temporal_storage.glsl>
#moj_import <minecraft:utilities/float_storage.glsl>
#moj_import <minecraft:globals.glsl>

uniform sampler2D Previous;

in float exposure;

out vec4 fragColor;

const int CAMERA_POSITION_X_INDEX = 0;
const int CAMERA_POSITION_Y_INDEX = 1;
const int CAMERA_POSITION_Z_INDEX = 2;
const int TIME_INDEX = 3;
const int EXPOSURE_INDEX = 4;

void main() {
    int index = int(gl_FragCoord.x);
    switch (index) {
        case CAMERA_POSITION_X_INDEX:
        fragColor = encodeFloat(float(CameraBlockPos.x) - CameraOffset.x);
        break;
        case CAMERA_POSITION_Y_INDEX:
        fragColor = encodeFloat(float(CameraBlockPos.y) - CameraOffset.y);
        break;
        case CAMERA_POSITION_Z_INDEX:
        fragColor = encodeFloat(float(CameraBlockPos.z) - CameraOffset.z);
        break;
        case TIME_INDEX:
        fragColor = encodeFloat(GameTime);
        break;
        case EXPOSURE_INDEX:
        fragColor = encodeFloat(exposure);
        break;
        default:
        discard;
    }
}

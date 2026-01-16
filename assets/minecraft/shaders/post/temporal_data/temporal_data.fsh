#version 400

#moj_import <minecraft:utilities/temporal_storage.glsl>
#moj_import <minecraft:utilities/float_storage.glsl>
#moj_import <minecraft:globals.glsl>

in float exposure;
in mat4 projMat;
in mat4 viewMat;

out vec4 fragColor;

const int CAMERA_POSITION_X_INDEX = 0;
const int CAMERA_POSITION_Y_INDEX = 1;
const int CAMERA_POSITION_Z_INDEX = 2;
const int TIME_INDEX = 3;
const int EXPOSURE_INDEX = 4;
const int PROJ_INDEX = 5;
const int VIEW_INDEX = 6;

void main() {
    int index = int(gl_FragCoord.x);
    if (index <= 2) {
        fragColor = encodeFloat(float(CameraBlockPos[index]) - fract(CameraOffset[index]));
    } else if (index == 3) {
        fragColor = encodeFloat(GameTime);
    } else if (index == 4) {
        fragColor = encodeFloat(exposure);
    } else if (index <= 20) {
        int i = index - 5;
        fragColor = encodeFloat(projMat[i % 4][i / 4]);
    } else if (index <= 36) {
        int i = index - 21;
        fragColor = encodeFloat(viewMat[i % 4][i / 4]);
    }
}

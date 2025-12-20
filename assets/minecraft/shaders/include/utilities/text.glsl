#version 420

#if !defined(TEXT_GLSL)
#define TEXT_GLSL

const uint _A = 1663026734u;
const uint _B = 1595457071u;
const uint _C = 1561364014u;
const uint _D = 1595459119u;
const uint _E = 2115017791u;
const uint _F = 1108393023u;
const uint _G = 1562281518u;
const uint _H = 1662582321u;
const uint _I = 1547833486u;
const uint _J = 1561870879u;
const uint _K = 1653970225u;
const uint _L = 2115011617u;
const uint _M = 1662572401u;
const uint _N = 1671091825u;
const uint _O = 1561904686u;
const uint _P = 1108854319u;
const uint _Q = 1822082606u;
const uint _R = 1381484079u;
const uint _S = 1561868350u;
const uint _T = 1212289183u;
const uint _U = 1561904689u;
const uint _V = 1218790961u;
const uint _W = 1431881265u;
const uint _X = 1654985041u;
const uint _Y = 1212289361u;
const uint _Z = 2115047711u;
const uint _EXCLM = 1208094852u; // "!"
const uint _QUEST = 1208369710u; // "?"
const uint _DOT = 1207959552u;   // "."
const uint _UNDER = 2113929216u; // "_"
const uint _DASH = 1073756160u;  // "-"
const uint _SPACE = 0u;          // " "
const uint _SLASH = 35787024u;   // "/"
const uint _BSLSH = 545394753u;  // "\"
const uint _COLON = 4194432u;    // ":"
const uint _SEMI = 71434368u;    // ";"

const uvec2 TEXT_SIZE = uvec2(5, 6);
const uvec2 CHAR_PADDING = uvec2(6, 12);

#define TEXT(offset, fragCoord, str, outColor, filledColor, emptyColor) \
    { \
        uint[] chars = uint[] str; \
        uvec2 delta = uvec2(fragCoord) - uvec2(offset); \
        uint index = (delta.x / CHAR_PADDING.x) % chars.length(); \
        uvec2 pixel = delta % CHAR_PADDING; \
        outColor = emptyColor; \
        if (pixel.x < TEXT_SIZE.x && pixel.y < TEXT_SIZE.y) { \
            uint bit = pixel.x + (TEXT_SIZE.y - pixel.y - 1u) * TEXT_SIZE.x; \
            if (((chars[index] >> bit) & 1u) == 1u) { \
                outColor = filledColor; \
            } \
        }\
    }

#endif // TEXT_GLSL
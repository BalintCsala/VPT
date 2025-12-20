import fs from "fs/promises";

interface Setting {
  type:
    | "float"
    | "vec2"
    | "vec3"
    | "vec4"
    | "int"
    | "ivec2"
    | "ivec3"
    | "ivec4";
  name: string;
  value: number[];
}

// prettier-ignore
export async function generateSettingsFile(settings: Setting[]) {
  await fs.writeFile(
    "./assets/minecraft/shaders/include/settings.glsl",
    `#version 420

#if !defined(SETTINGS_GLSL)
#define SETTINGS_GLSL

${settings.map((setting) => `const ${setting.type} ${setting.name} = ${setting.type}(${setting.value.join(", ")});`).join("\n")}

#endif // SETTINGS_GLSL`
  );
}

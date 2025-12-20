import {
  FileInput,
  Pass,
  Pipeline,
  Target,
  TargetInput,
  implicitCloudsTarget,
  implicitItemEntityTarget,
  implicitMainTarget,
  implicitParticlesTarget,
  implicitTranslucentTarget,
  implicitWeatherTarget,
} from "./lib/pipeline.ts";

import fs from "fs/promises";
import { generateSettingsFile } from "./lib/settings.ts";
import { applyBloom } from "./bloom/Bloom.ts";

// Assuming some crazy person runs the shader on a super ultrawide 2x4k screen
const MAX_WIDTH = 7920;
const MAX_HEIGHT = 2160;

generateSettingsFile([
  { name: "MAX_RESOLUTION", type: "ivec2", value: [MAX_WIDTH, MAX_HEIGHT] },
]);

const pipeline = new Pipeline();

const normals = pipeline.addTarget(new Target("normals"));
pipeline.addPass(
  new Pass(
    "minecraft:post/initial_ray/initial_ray",
    "minecraft:post/initial_ray/geometry_normal",
    {},
    [
      new TargetInput("Data", implicitMainTarget),
      new TargetInput("DataDepth", implicitMainTarget, true),
      new TargetInput("Depth", implicitMainTarget, true),
      new FileInput("Atlas", "minecraft:atlas"),
      new FileInput("ModelData", "minecraft:model_data"),
    ],
    normals,
  ),
);

const translucentNormals = pipeline.addTarget(
  new Target("translucent_normals"),
);
pipeline.addPass(
  new Pass(
    "minecraft:post/initial_ray/initial_ray",
    "minecraft:post/initial_ray/geometry_normal",
    {},
    [
      new TargetInput("Data", implicitMainTarget),
      new TargetInput("DataDepth", implicitMainTarget, true),
      new TargetInput("Depth", implicitTranslucentTarget, true),
      new FileInput("Atlas", "minecraft:atlas"),
      new FileInput("ModelData", "minecraft:model_data"),
    ],
    translucentNormals,
  ),
);

const materialNormals = pipeline.addTarget(new Target("material_normal"));
pipeline.addPass(
  new Pass(
    "minecraft:post/initial_ray/initial_ray",
    "minecraft:post/initial_ray/normal",
    {},
    [
      new TargetInput("Data", implicitMainTarget),
      new TargetInput("DataDepth", implicitMainTarget, true),
      new TargetInput("Normal", normals),
      new FileInput("Atlas", "minecraft:atlas"),
      new FileInput("ModelData", "minecraft:model_data"),
    ],
    materialNormals,
  ),
);

const materialSpecular = pipeline.addTarget(new Target("material_specular"));
pipeline.addPass(
  new Pass(
    "minecraft:post/initial_ray/initial_ray",
    "minecraft:post/initial_ray/specular",
    {},
    [
      new TargetInput("Data", implicitMainTarget),
      new TargetInput("DataDepth", implicitMainTarget, true),
      new FileInput("Atlas", "minecraft:atlas"),
      new FileInput("ModelData", "minecraft:model_data"),
    ],
    materialSpecular,
  ),
);

let radiance = pipeline.addTarget(new Target("radiance"));
pipeline.addPass(
  new Pass(
    "minecraft:post/direct_light/direct_light",
    "minecraft:post/direct_light/direct_light",
    {},
    [
      new TargetInput("Data", implicitMainTarget),
      new TargetInput("DataDepth", implicitMainTarget, true),
      new TargetInput("TranslucentDepth", implicitTranslucentTarget, true),
      new FileInput("Atlas", "minecraft:atlas"),
      new FileInput("ModelData", "minecraft:model_data"),
      new TargetInput("MaterialNormal", materialNormals),
      new TargetInput("MaterialSpecular", materialSpecular),
    ],
    radiance,
  ),
);

// const sky = pipeline.addTarget(new Target("sky", 512, 512));
// pipeline.addPass(
//   new Pass(
//     "minecraft:post/render_sky/render_sky",
//     "minecraft:post/render_sky/render_sky",
//     {},
//     [new TargetInput("Data", implicitMainTarget)],
//     sky
//   )
// );

/*const diffuseGI = pipeline.addTarget(new Target("diffuse_gi"));
pipeline.addPass(
  new Pass(
    "minecraft:post/diffuse_gi/diffuse_gi",
    "minecraft:post/diffuse_gi/diffuse_gi",
    {},
    [
      new TargetInput("Data", implicitMainTarget),
      new TargetInput("DataDepth", implicitMainTarget, true),
      new TargetInput("TranslucentDepth", implicitTranslucentTarget, true),
      new TargetInput("Normal", normals),
      new TargetInput("TranslucentNormal", translucentNormals),
      new FileInput("Atlas", "minecraft:atlas"),
      new FileInput("ModelData", "minecraft:model_data"),
      new TargetInput("MaterialNormal", materialNormals),
      new TargetInput("MaterialSpecular", materialSpecular),
    ],
    diffuseGI
  )
);*/

/*const hdr = pipeline.addTarget(new Target("hdr"));
pipeline.addPass(
  new Pass(
    "minecraft:post/screenquad",
    "minecraft:post/combine_gi/combine_gi",
    {},
    [
      new TargetInput("DirectLight", directLight),
      //new TargetInput("DiffuseGI", diffuseGI),
      //new TargetInput("Albedo", implicitMainTarget),
    ],
    hdr
  )
);*/

const sky = pipeline.addTarget(new Target("sky"));
pipeline.addPass(
  new Pass(
    "minecraft:post/sky/render_sky",
    "minecraft:post/sky/render_sky",
    {},
    [
      new TargetInput("Depth", implicitMainTarget, true),
      new TargetInput("Data", implicitMainTarget),
    ],
    sky,
  ),
);

pipeline.addPass(
  new Pass(
    "minecraft:post/sky/add_sky",
    "minecraft:post/sky/add_sky",
    {},
    [
      new TargetInput("Depth", implicitMainTarget, true),
      new TargetInput("Sky", sky),
    ],
    radiance,
  ),
);

let radianceSwap = pipeline.addTarget(new Target("radiance_swap"));
pipeline.addPass(
  new Pass(
    "minecraft:post/water/water",
    "minecraft:post/water/water",
    {},
    [
      new FileInput("Atlas", "minecraft:atlas"),
      new FileInput("ModelData", "minecraft:model_data"),
      new TargetInput("Data", implicitMainTarget),
      new TargetInput("Solid", radiance),
      new TargetInput("Depth", implicitMainTarget, true),
      new TargetInput("Translucent", implicitTranslucentTarget),
      new TargetInput("TranslucentDepth", implicitTranslucentTarget, true),
      new TargetInput("MaterialNormal", materialNormals),
      new TargetInput("MaterialSpecular", materialSpecular),
    ],
    radianceSwap,
  ),
);
[radiance, radianceSwap] = [radianceSwap, radiance];

const bloomResult = applyBloom(pipeline, radiance, MAX_WIDTH, MAX_HEIGHT, 12);

const final = pipeline.addTarget(new Target("final"));
pipeline.addPass(
  new Pass(
    "minecraft:post/screenquad",
    "minecraft:post/hdr_output/hdr_output",
    {},
    [
      new TargetInput("Direct", radiance),
      new TargetInput("Bloom", bloomResult),
    ],
    final,
  ),
);

const result = pipeline.addTarget(new Target("result"));
pipeline.addPass(
  new Pass(
    "minecraft:post/screenquad",
    "minecraft:post/transparency",
    {},
    [
      new TargetInput("Main", final),
      new TargetInput("MainDepth", implicitMainTarget, true),
      new TargetInput("ItemEntity", implicitItemEntityTarget),
      new TargetInput("ItemEntityDepth", implicitItemEntityTarget, true),
      new TargetInput("Particles", implicitParticlesTarget),
      new TargetInput("ParticlesDepth", implicitParticlesTarget, true),
      new TargetInput("Clouds", implicitCloudsTarget),
      new TargetInput("CloudsDepth", implicitCloudsTarget, true),
      new TargetInput("Weather", implicitWeatherTarget),
      new TargetInput("WeatherDepth", implicitWeatherTarget, true),
    ],
    result,
  ),
);

pipeline.addPass(
  new Pass(
    "minecraft:post/screenquad",
    "minecraft:post/blit",
    {
      BlitConfig: [
        {
          name: "ColorModulate",
          type: "vec4",
          value: [1, 1, 1, 1],
        },
      ],
    },
    [new TargetInput("In", result)],
    implicitMainTarget,
  ),
);

await fs.writeFile(
  "assets/minecraft/post_effect/transparency.json",
  JSON.stringify(pipeline.generate(), null, 2),
);

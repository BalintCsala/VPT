import { Pass, Pipeline, Target, TargetInput } from "../lib/pipeline.ts";

export function calculateNormals(
  pipeline: Pipeline,
  data: Target,
  depth: Target,
  resultName: string
) {
  const result = pipeline.addTarget(new Target(resultName));
  pipeline.addPass(
    new Pass(
      "minecraft:post/calculate_normals/calculate_normals",
      "minecraft:post/calculate_normals/calculate_normals",
      {},
      [new TargetInput("Data", data), new TargetInput("Depth", depth, true)],
      result
    )
  );
  return result;
}

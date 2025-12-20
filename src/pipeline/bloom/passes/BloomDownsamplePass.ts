import { Pass, Target, TargetInput } from "../../lib/pipeline.ts";

export class BloomDownsamplePass extends Pass {
  constructor(previousMip: Target, nextMip: Target) {
    super(
      "minecraft:post/bloom/bloom_mip",
      "minecraft:post/bloom/downsample",
      {},
      [new TargetInput("In", previousMip)],
      nextMip
    );
  }
}

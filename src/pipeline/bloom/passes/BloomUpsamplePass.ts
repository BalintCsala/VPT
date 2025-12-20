import { Pass, Target, TargetInput } from "../../lib/pipeline.ts";

export class BloomUpsamplePass extends Pass {
  constructor(previousMip: Target, currentMip: Target, output: Target) {
    super(
      "minecraft:post/bloom/bloom_mip",
      "minecraft:post/bloom/upsample",
      {},
      [
        new TargetInput("PreviousMip", previousMip),
        new TargetInput("CurrentMip", currentMip),
      ],
      output
    );
  }
}

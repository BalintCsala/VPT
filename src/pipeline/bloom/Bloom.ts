import { Pipeline, Target } from "../lib/pipeline.ts";
import { BloomDownsamplePass } from "./passes/BloomDownsamplePass.ts";
import { BloomUpsamplePass } from "./passes/BloomUpsamplePass.ts";

export function applyBloom(
  pipeline: Pipeline,
  hdrResult: Target,
  maxWidth: number,
  maxHeight: number,
  steps: number
) {
  const bloomMipTargets = [hdrResult];

  let nextBloomMipWidth = maxWidth / 2;
  let nextBloomMipHeight = maxHeight / 2;
  // Starting at 1 since mip0 is the output of the previous pass
  for (let i = 1; i < steps; i++) {
    const previousBloomMip = bloomMipTargets[i - 1];
    const nextBloomMip = pipeline.addTarget(
      new Target(`bloom_down_${i}`, nextBloomMipWidth, nextBloomMipHeight)
    );
    pipeline.addPass(new BloomDownsamplePass(previousBloomMip, nextBloomMip));

    bloomMipTargets.push(nextBloomMip);
    nextBloomMipWidth = Math.ceil(nextBloomMipWidth / 2);
    nextBloomMipHeight = Math.ceil(nextBloomMipHeight / 2);
  }

  nextBloomMipWidth *= 2;
  nextBloomMipHeight *= 2;
  for (let i = steps - 2; i >= 0; i--) {
    nextBloomMipWidth *= 2;
    nextBloomMipHeight *= 2;
    const prevMip = bloomMipTargets[i + 1];
    const currMip = bloomMipTargets[i];
    const upsampleMip = pipeline.addTarget(
      new Target(`bloom_up_${i}`, nextBloomMipWidth, nextBloomMipHeight)
    );
    pipeline.addPass(new BloomUpsamplePass(prevMip, currMip, upsampleMip));
    bloomMipTargets[i] = upsampleMip;
  }
  return bloomMipTargets[0];
}

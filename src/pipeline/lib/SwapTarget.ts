import { Pass, Pipeline, Target } from "./pipeline.ts";

export class SwapTarget {
  output: Target;
  input: Target;

  constructor(
    pipeline: Pipeline,
    name: string,
    width?: number,
    height?: number
  ) {
    this.output = new Target(`${name}_a`, width, height);
    this.input = new Target(`${name}_b`, width, height);
    pipeline.addTarget(this.output);
    pipeline.addTarget(this.input);
  }

  swap() {
    [this.output, this.input] = [this.input, this.output];
  }
}

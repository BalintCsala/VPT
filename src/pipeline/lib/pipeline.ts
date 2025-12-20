export interface Uniform {
  name: string;
  type: "int" | "ivec3" | "float" | "vec2" | "vec3" | "vec4" | "matrix4x4";
  value: number[];
}

export class Target {
  name: string;
  width?: number;
  height?: number;
  persistent: boolean;
  clearColor: [number, number, number, number];
  usedAsInput: boolean;
  usedAsOutput: boolean;

  constructor(name: string, width?: number, height?: number) {
    this.name = name;
    this.width = width;
    this.height = height;
    this.persistent = true; // True by default to save on clearing costs
    this.clearColor = [0, 0, 0, 0];
    this.usedAsInput = false;
    this.usedAsOutput = false;
  }

  setPersistent(persistent: boolean) {
    this.persistent = persistent;
    return this;
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    this.clearColor = [r, g, b, a];
    return this;
  }

  generate() {
    let result = {
      persistent: this.persistent,
    } as {
      name: string;
      width?: number;
      height?: number;
      persistent: boolean;
      clear_color?: [number, number, number, number];
    };
    if (this.persistent) {
      result.clear_color = this.clearColor;
    }
    if (this.width) {
      result.width = this.width;
    }
    if (this.height) {
      result.height = this.height;
    }
    return result;
  }
}

abstract class Input {
  samplerName: string;
  bilinear: boolean;

  constructor(samplerName: string, bilinear: boolean) {
    this.samplerName = samplerName;
    this.bilinear = bilinear;
  }

  abstract generate(): object;
}

export class FileInput extends Input {
  #file: string;

  constructor(samplerName: string, file: string, bilinear: boolean = false) {
    super(samplerName, bilinear);
    this.#file = file;
  }

  generate() {
    return {
      sampler_name: this.samplerName,
      bilinear: this.bilinear,
      location: this.#file,
      width: 1,
      height: 1,
    };
  }
}

export class TargetInput extends Input {
  #target: Target;
  #useDepth: boolean;

  constructor(
    samplerName: string,
    target: Target,
    useDepth: boolean = false,
    bilinear: boolean = false
  ) {
    super(samplerName, bilinear);
    this.#target = target;
    this.#useDepth = useDepth;
  }

  generate(): object {
    this.#target.usedAsInput = true;
    return {
      sampler_name: this.samplerName,
      bilinear: this.bilinear,
      target: this.#target.name,
      use_depth_buffer: this.#useDepth,
    };
  }
}

export class Pass {
  #vertexShader: string;
  #fragmentShader: string;
  #uniforms: { [key: string]: Uniform[] };
  #inputs: Input[];
  #output: Target;

  constructor(
    vertexShader: string,
    fragmentShader: string,
    uniforms: { [key: string]: Uniform[] },
    inputs: Input[],
    output: Target
  ) {
    this.#vertexShader = vertexShader;
    this.#fragmentShader = fragmentShader;
    this.#uniforms = uniforms;
    this.#inputs = inputs;
    this.#output = output;
  }

  generate() {
    this.#output.usedAsOutput = true;
    return {
      vertex_shader: this.#vertexShader,
      fragment_shader: this.#fragmentShader,
      inputs: this.#inputs.map((input) => input.generate()),
      output: this.#output.name,
      uniforms: this.#uniforms,
    };
  }
}

export class Pipeline {
  #targets: Map<string, Target>;
  #passes: Pass[];

  constructor() {
    this.#targets = new Map();
    this.#passes = [];
  }

  addTarget(target: Target) {
    this.#targets.set(target.name, target);
    return target;
  }

  addPass(pass: Pass) {
    this.#passes.push(pass);
    return pass;
  }

  generate() {
    const result = {
      targets: {},
      passes: this.#passes.map((pass) => pass.generate()),
    };
    this.#targets.forEach((target, name) => {
      if (!target.usedAsOutput) return;
      // @ts-ignore
      result.targets[name] = target.generate();
    });

    this.#targets.forEach((target) => {
      if (!target.usedAsInput) {
        console.warn(`Target ${target.name} was never read from`);
      }
      if (!target.usedAsOutput) {
        console.warn(`Target ${target.name} was never written to`);
      }
    });

    return result;
  }
}

export const implicitMainTarget = new Target("minecraft:main");
export const implicitTranslucentTarget = new Target("minecraft:translucent");
export const implicitItemEntityTarget = new Target("minecraft:item_entity");
export const implicitParticlesTarget = new Target("minecraft:particles");
export const implicitCloudsTarget = new Target("minecraft:clouds");
export const implicitWeatherTarget = new Target("minecraft:weather");

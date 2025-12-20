import JSZip from "jszip";
import { sanitizeReference } from "./sanitization.ts";

export type FaceDirection = "down" | "up" | "north" | "south" | "west" | "east";

export type Rotation = 0 | 90 | 180 | 270;

type Face = {
  uv?: [number, number, number, number];
  texture: string;
  cullface?: FaceDirection;
  rotation?: Rotation;
  tintindex?: number;
};

type Element = {
  from: [number, number, number];
  to: [number, number, number];
  rotation?: {
    origin: [number, number, number];
    axis: "x" | "y" | "z";
    angle: number;
    rescale?: boolean;
  };
  shade?: boolean;
  faces: {
    [key in FaceDirection]?: Face;
  };
};

export type Model = {
  parent?: string;
  ambientocclusion?: boolean;
  display?: unknown; // Unused
  textures: {
    [key: string]: string;
  };
  elements?: Element[];
  isParent?: boolean; // Custom flag
};

function flattenModelAncestry(
  name: string,
  model: Model,
  processedModels: Map<string, Model>,
  unprocessedModels: Map<string, Model>
): Model {
  if (!model.parent) {
    return model;
  }

  const parentName = sanitizeReference(model.parent);
  let parentModel = processedModels.get(parentName);
  if (!parentModel) {
    parentModel = unprocessedModels.get(parentName);
    if (!parentModel) {
      console.log(
        `Failed to open model file ${parentName} requested by ${name}`
      );
      return model;
    }
    parentModel = flattenModelAncestry(
      model.parent,
      parentModel,
      processedModels,
      unprocessedModels
    );
    processedModels.set(parentName, parentModel);
  }

  const newModel = {
    ...JSON.parse(JSON.stringify(parentModel)),
    ...model,
    parent: undefined,
    // Merge texture definitions
    textures: { ...(parentModel?.textures ?? {}), ...model.textures },
    isParent: false,
  };
  parentModel.isParent = true;

  return newModel;
}

export async function parseModels(zip: JSZip) {
  const unprocessedModels = new Map<string, Model>();
  const blockFolder = zip.folder("assets/minecraft/models/block");
  if (!blockFolder) {
    throw new Error("Block models missing from files");
  }
  const promises: Promise<void>[] = [];
  blockFolder.forEach((name, file) => {
    promises.push(
      (async (name, file) => {
        const content = JSON.parse(await file.async("string")) as Model;
        unprocessedModels.set(name.replace(".json", ""), content);
      })(name, file)
    );
  });
  await Promise.allSettled(promises);

  const processedModels = new Map<string, Model>();
  unprocessedModels.forEach((model, name) => {
    if (processedModels.has(name)) {
      // Already processed, we can skip it
      return;
    }

    const flatModel = flattenModelAncestry(
      name,
      model,
      processedModels,
      unprocessedModels
    );
    processedModels.set(name, flatModel);
  });

  return processedModels;
}

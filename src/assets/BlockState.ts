import JSZip from "jszip";
import type { FaceDirection, Model, Rotation } from "./Model.ts";
import type { TextureLocation } from "./Texture.ts";
import fs from "fs/promises";
import { getModelFaces, packModel } from "./FaceData.ts";
import { sanitizeReference } from "./sanitization.ts";
import { encode } from "fast-png";

type ModelInfo = {
  model: string;
  x?: Rotation;
  y?: Rotation;
  uvlock?: boolean;
};

type WeightedModelInfo = ModelInfo & {
  weight?: number;
};

type Condition = {
  [key: string]: string;
};

type OrCondition = {
  OR: Condition[];
};

type AndCondition = {
  AND: Condition[];
};

type Variants = {
  [key: string]: WeightedModelInfo[] | ModelInfo;
};

type Multipart = {
  when?: Condition | OrCondition | AndCondition;
  apply: WeightedModelInfo[] | ModelInfo;
}[];

type BlockState = {
  variants?: Variants;
  multipart?: Multipart;
};

const DATA_TEXTURE_SIZE = 16;

const BLOCK_STATE_PARSE_REGEX = /^(\w+)\[(.*)\]$/;

const BLOCK_STATE_IGNORE_LIST = new Set([
  "mangrove_propagule",
  "short_grass",
  "fern",
  "short_dry_grass",
  "tall_dry_grass",
  "tall_seagrass",
  "dandelion",
  "torchflower",
  "poppy",
  "blue_orchid",
  "allium",
  "azure_bluet",
  "red_tulip",
  "orange_tulip",
  "white_tulip",
  "pink_tulip",
  "oxeye_daisy",
  "cornflower",
  "wither_rose",
  "lily_of_the_valley",
  "lily_of_the_valley",
  "sunflower",
  "lilac",
  "rose_bush",
  "peony",
  "tall_grass",
  "large_fern",
  "pitcher_plant",
  "bamboo_sapling",
  "bamboo",
  "warped_roots",
  "nether_sprouts",
  "crimson_root",
  "pointed_dripstone",
  "small_dripleaf",
  "hanging_roots",
  "open_eyeblossom",
  "closed_eyeblossom",
]);

export async function parsePossibleBlockstates() {
  const blockstateDescriptions = (
    await fs.readFile("./src/resources/possible_blockstates.txt")
  )
    .toString()
    .split("\n");
  const possibleBlockstates = new Map<string, { [key: string]: string }[]>();
  blockstateDescriptions.forEach((blockstate) => {
    if (blockstate.indexOf("[") == -1) {
      blockstate += "[]";
    }

    const [, block, states] = BLOCK_STATE_PARSE_REGEX.exec(blockstate)!;

    let blockstateList = possibleBlockstates.get(block);
    if (!blockstateList) {
      blockstateList = [];
      possibleBlockstates.set(block, blockstateList);
    }
    if (states.length == 0) {
      return;
    }

    const compoundState: { [key: string]: string } = {};
    states.split(",").map((stateValue) => {
      const [state, value] = stateValue.split("=");
      compoundState[state] = value;
    });
    blockstateList.push(compoundState);
  });

  BLOCK_STATE_IGNORE_LIST.forEach((ignored) =>
    possibleBlockstates.delete(ignored)
  );

  return possibleBlockstates;
}

function generateDataTexture(zip: JSZip, id: number, textureName: string) {
  const data = new Uint8Array(DATA_TEXTURE_SIZE * DATA_TEXTURE_SIZE * 4);
  const payload = [id & 255, (id >> 8) & 255, 0, 255];

  for (let x = 1; x < DATA_TEXTURE_SIZE - 1; x++) {
    for (let y = 1; y < DATA_TEXTURE_SIZE - 1; y++) {
      const index = (x + y * DATA_TEXTURE_SIZE) * 4;
      if (x >= 6 && y >= 6 && x < 10 && y < 10) {
        data.set([255, 0, 255, 123], index);
      } else {
        data.set(payload, index);
      }
    }
  }
  const texture = encode({
    data,
    width: DATA_TEXTURE_SIZE,
    height: DATA_TEXTURE_SIZE,
    channels: 4,
    depth: 8,
  });
  zip.file(`assets/minecraft/textures/block/${textureName}.png`, texture);
}

function removeShading(model: Model) {
  model.ambientocclusion = false;
  if (model.elements) {
    model.elements.forEach((element) => (element.shade = false));
  }
}

function addDataQuadToModel(
  modelInfo: ModelInfo,
  model: Model,
  dataTextureName: string
) {
  let faces = ["up", "down"] as FaceDirection[];
  if (modelInfo.x == 90) {
    faces = ["south", "north"];
  }

  model.elements?.push({
    from: [7, 7, 7],
    to: [9, 9, 9],
    faces: {
      [faces[0]]: {
        uv: [7, 7, 9, 9],
        texture: "#__data",
        tintindex: 1,
      },
      [faces[1]]: {
        uv: [7, 7, 9, 9],
        texture: "#__data",
        tintindex: 1,
      },
    },
  });
}

function addDataQuadToExistingModel(
  zip: JSZip,
  modelInfo: ModelInfo,
  model: Model,
  dataTextureName: string,
  modelName: string
) {
  const copy = JSON.parse(JSON.stringify(model)) as Model;
  copy.textures["__data"] = `block/${dataTextureName}`;
  addDataQuadToModel(modelInfo, copy, dataTextureName);
  removeShading(copy);
  zip.file(
    `assets/minecraft/models/block/${modelName}.json`,
    JSON.stringify(copy, null, 4)
  );
}

function createNewModelWithDataQuad(
  zip: JSZip,
  modelInfo: ModelInfo,
  dataTextureName: string,
  modelName: string
) {
  const model: Model = {
    textures: {},
    elements: [],
  };
  model.textures["__data"] = `block/${dataTextureName}`;
  model.textures["particle"] = `block/${dataTextureName}`;
  addDataQuadToModel(modelInfo, model, dataTextureName);
  removeShading(model);
  zip.file(
    `assets/minecraft/models/block/${modelName}.json`,
    JSON.stringify(model, null, 4)
  );
}

function generateAssetsForModelInfo<T extends ModelInfo>(
  zip: JSZip,
  variantName: string,
  models: Map<string, Model>,
  modelInfo: T,
  modelId: number
): T {
  const newModelName = `${variantName}__model_`;
  const dataTextureName = `${variantName}__data_`;

  const model = models.get(sanitizeReference(modelInfo.model));
  if (model) {
    addDataQuadToExistingModel(
      zip,
      modelInfo,
      model,
      dataTextureName,
      newModelName
    );
  } else {
    createNewModelWithDataQuad(zip, modelInfo, dataTextureName, newModelName);
  }

  generateDataTexture(zip, modelId, dataTextureName);
  return {
    ...modelInfo,
    model: `block/${newModelName}`,
  };
}

async function parseVariants(
  zip: JSZip,
  blockstateName: string,
  variants: Variants,
  models: Map<string, Model>,
  textureLocations: Map<string, TextureLocation>,
  generatedModelData: Uint8Array[],
  idMapping: Map<string, number>
) {
  let generatedModels = 0;
  for (const variant in variants) {
    let value = variants[variant];
    if (!Array.isArray(value)) {
      value = [value];
    }

    const newModels: WeightedModelInfo[] = [];
    for (const modelInfo of value) {
      const modelId = generatedModelData.length;
      const model = models.get(sanitizeReference(modelInfo.model));
      if (!model) {
        console.log(
          `Could not find model named "${sanitizeReference(
            modelInfo.model
          )}" in variants "${blockstateName}"`
        );
        return;
      }
      const faces = getModelFaces(
        modelInfo.model,
        model,
        textureLocations,
        modelInfo.x,
        modelInfo.y
      );

      if (faces.length == 0) {
        return;
      }

      generatedModelData.push(packModel(faces));

      const uniqueVariantName = `generated__${blockstateName}__${generatedModels++}`;
      idMapping.set(uniqueVariantName, modelId);
      newModels.push(
        generateAssetsForModelInfo(
          zip,
          uniqueVariantName,
          models,
          modelInfo,
          modelId
        )
      );
    }
    variants[variant] = newModels;
  }
}

function isConditionFulfilled(
  state: {
    [key: string]: string;
  },
  condition: Condition
) {
  for (const key in condition) {
    if (!state[key] || condition[key].split("|").indexOf(state[key]) == -1) {
      return false;
    }
  }

  return true;
}

async function parseMultipart(
  zip: JSZip,
  blockstateName: string,
  multipart: Multipart,
  models: Map<string, Model>,
  textureLocations: Map<string, TextureLocation>,
  generatedModelData: Uint8Array[],
  possibleBlockstates: Map<string, { [key: string]: string }[]>,
  idMapping: Map<string, number>
) {
  let generatedModels = 0;
  const combinations = possibleBlockstates.get(blockstateName);
  if (combinations == undefined) {
    console.log("This state shouldn't be reachable");
    return;
  }

  const newParts: Multipart = [];
  for (const combination of combinations) {
    const uniqueModelName = `generated__${blockstateName}__${generatedModels++}`;

    const modelId = generatedModelData.length;
    idMapping.set(uniqueModelName, modelId);

    const modelInfos: ModelInfo[] = [];
    multipart.forEach((part) => {
      // prettier-ignore
      if (
        !part.when ||
        (Object.hasOwn(part.when, "AND") && (part.when as AndCondition).AND.every((condition) => isConditionFulfilled(combination, condition))) ||
        (Object.hasOwn(part.when, "OR") && (part.when as OrCondition).OR.some((condition) => isConditionFulfilled(combination, condition))) ||
        isConditionFulfilled(combination, part.when as Condition)
      ) {
        modelInfos.push(Array.isArray(part.apply) ? part.apply[0] : part.apply);
      }
    });

    const faces = modelInfos.flatMap((modelInfo) => {
      const model = models.get(sanitizeReference(modelInfo.model));
      if (!model) {
        console.log(
          `Could not find model named "${sanitizeReference(
            modelInfo.model
          )}" in multipart "${blockstateName}"`
        );
        return [];
      }

      return getModelFaces(
        modelInfo.model,
        model,
        textureLocations,
        modelInfo.x,
        modelInfo.y
      );
    });

    if (faces.length == 0) {
      return [];
    }

    generatedModelData.push(packModel(faces));

    newParts.push({
      when: combination,
      apply: generateAssetsForModelInfo(
        zip,
        uniqueModelName,
        models,
        { model: "" },
        modelId
      ),
    });
  }
  multipart.push(...newParts);
}

export async function generateAssets(
  zip: JSZip,
  models: Map<string, Model>,
  textureLocations: Map<string, TextureLocation>
) {
  const folder = zip.folder("assets/minecraft/blockstates/");
  if (!folder) {
    console.log("Failed to find the blockstates folder!");
    return;
  }
  const generatedModelData: Uint8Array[] = [];
  const idMapping = new Map<string, number>();

  const possibleBlockstates = await parsePossibleBlockstates();

  const files: [string, JSZip.JSZipObject][] = [];
  folder.forEach((path, file) => files.push([path, file]));

  for (const [path, file] of files) {
    const content = await file.async("string");
    const blockstateName = path.replace(".json", "");

    if (possibleBlockstates.get(blockstateName) == undefined) {
      // This blockstate was deliberately excluded, probably because it's a block entity
      continue;
    }

    const blockstate = JSON.parse(content) as BlockState;
    if (blockstate.variants) {
      await parseVariants(
        zip,
        blockstateName,
        blockstate.variants,
        models,
        textureLocations,
        generatedModelData,
        idMapping
      );
    } else {
      await parseMultipart(
        zip,
        blockstateName,
        blockstate.multipart!,
        models,
        textureLocations,
        generatedModelData,
        possibleBlockstates,
        idMapping
      );
    }

    // Write the modified blockstate out
    zip.file(
      `assets/minecraft/blockstates/${path}`,
      JSON.stringify(blockstate, null, 4)
    );
  }

  const modelDataWidth = Math.max(
    ...generatedModelData.map((modelData) => modelData.length / 4)
  );

  const modelDataTexture = new Uint8Array(
    modelDataWidth * generatedModelData.length * 4
  );
  generatedModelData.forEach((modelData, y) => {
    modelDataTexture.set(modelData, y * modelDataWidth * 4);
  });

  const imageData = encode({
    data: modelDataTexture,
    width: modelDataWidth,
    height: generatedModelData.length,
    channels: 4,
    depth: 8,
  });
  zip.file(`assets/minecraft/textures/effect/model_data.png`, imageData);

  await fs.writeFile(
    `./out/ids.txt`,
    [...idMapping.entries()].map(([name, id]) => `${name} = ${id}`).join("\n")
  );
}

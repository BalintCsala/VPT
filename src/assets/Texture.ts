import { convertIndexedToRgb, decode, encode } from "fast-png";
import type { DecodedPng } from "fast-png";
import JSZip from "jszip";

export type TextureLocation = {
  x: number;
  y: number;
  size: number;
  cutout: boolean;
};

function indexToMorton(index: number) {
  let x = 0;
  let y = 0;
  for (let i = 0; i < 32; i++) {
    let bit = (index >> i) & 1;
    let value = bit << Math.floor(i / 2);
    if (i % 2 == 0) {
      x |= value;
    } else {
      y |= value;
    }
  }
  return { x, y };
}

export async function generateAtlas(zip: JSZip) {
  const textureFolder = zip.folder("assets/minecraft/textures/block");
  if (!textureFolder) {
    throw new Error("Block textures missing from files");
  }

  const textureFiles = new Map<string, JSZip.JSZipObject>();

  textureFolder.forEach((path, file) => {
    if (
      !path.endsWith(".png") ||
      path.endsWith("_n.png") ||
      path.endsWith("_s.png") ||
      path.endsWith("_inventory.png") // Special case for textureless, we don't need these in the atlas
    ) {
      return;
    }
    let name = path.replace(".png", "");
    textureFiles.set(name, file);
  });

  let textures: {
    name: string;
    texture: DecodedPng;
    n?: DecodedPng;
    s?: DecodedPng;
    size: number;
  }[] = [];

  const count = textureFiles.size;
  let maxLength = 0;
  let i = 0;
  for (const [name, file] of textureFiles) {
    const message = `[${++i}/${count}] ${name}`;
    maxLength = Math.max(maxLength, message.length);
    process.stdout.write(message.padEnd(maxLength, " ") + "\r");
    const data = await file.async("uint8array");
    const sFile = zip.file(`assets/minecraft/textures/block/${name}_s.png`);
    const nFile = zip.file(`assets/minecraft/textures/block/${name}_n.png`);

    const texture = decode(data);
    textures.push({
      name,
      texture,
      s: sFile ? decode(await sFile.async("uint8array")) : undefined,
      n: nFile ? decode(await nFile.async("uint8array")) : undefined,
      size: Math.min(texture.width, texture.height),
    });
  }
  process.stdout.write(" ".repeat(maxLength) + "\r");

  textures = textures.sort((a, b) => (a.size > b.size ? -1 : 1));

  const textureLocations = new Map<string, TextureLocation>();
  let requiredPixels = textures.reduce(
    (sum, texture) => sum + texture.size * texture.size,
    0,
  );

  const atlasSize = 2 ** Math.ceil(Math.log2(requiredPixels) / 2);

  const atlasData = new Uint8Array(atlasSize * atlasSize * 4 * 4);

  let index = 0;
  textures.forEach(({ name, texture, size, n, s }) => {
    if (texture.palette) {
      texture.data = convertIndexedToRgb(texture);
      texture.channels = texture.palette[0].length;
      texture.depth = 8;
      texture.palette = undefined;
    }

    const location = indexToMorton(index);

    let cutout = false;
    for (let x = 0; x < size; x++) {
      for (let y = 0; y < size; y++) {
        let pixelIndex = (x + y * texture.width) * texture.channels;
        const pixelData = new Uint8Array([0, 0, 0, 255]);
        switch (texture.channels) {
          case 1: {
            let gray = texture.data[pixelIndex];
            pixelData.set([gray, gray, gray], 0);
            break;
          }
          case 2: {
            let gray = texture.data[pixelIndex];
            let alpha = texture.data[pixelIndex + 1];
            pixelData.set([gray, gray, gray, alpha]);
            break;
          }
          case 3:
          case 4:
            pixelData.set(
              texture.data.subarray(pixelIndex, pixelIndex + texture.channels),
            );
            break;
        }

        if (texture.transparency) {
          let transparent = true;
          for (let i = 0; i < texture.channels; i++) {
            if (pixelData[i] != texture.transparency[i]) {
              transparent = false;
              break;
            }
          }
          if (transparent) {
            pixelData[3] = 0;
          }
        }

        const nData = new Uint8Array([128, 128, 255, 255]);
        if (n) {
          const pixelIndex = (x + y * n.width) * n.channels;
          nData.set(n.data.subarray(pixelIndex, pixelIndex + n.channels), 0);
        }

        const sData = new Uint8Array([0, 0, 0, 255]);
        if (s) {
          const pixelIndex = (x + y * s.width) * s.channels;
          sData.set(s.data.subarray(pixelIndex, pixelIndex + s.channels), 0);
        }

        const outputIndex =
          (location.x + x + (location.y + y) * atlasSize * 2) * 4;
        atlasData.set(pixelData, outputIndex);
        atlasData.set(nData, outputIndex + atlasSize * 4);
        atlasData.set(sData, outputIndex + atlasSize * atlasSize * 2 * 4);

        if (pixelData[3] < 255) {
          cutout = true;
        }
      }
    }

    textureLocations.set(name, {
      ...location,
      size,
      cutout,
    });
    index += size * size;
  });

  zip.file(
    "assets/minecraft/textures/effect/atlas.png",
    encode({
      width: atlasSize * 2,
      height: atlasSize * 2,
      data: atlasData,
      depth: 8,
      channels: 4,
    }),
  );

  return {
    textureLocations,
  };
}

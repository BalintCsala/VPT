import fs from "fs/promises";
import JSZip from "jszip";
import { generateAssets } from "./BlockState.ts";
import { parseModels } from "./Model.ts";
import { generateAtlas } from "./Texture.ts";
import type { Version, VersionManifest } from "./types.ts";
import path from "path";

const VERSION_MANIFEST_URL =
  "https://piston-meta.mojang.com/mc/game/version_manifest.json";

const CURRENT_VERSION = "1.21.11";

const RESOURCEPACK_FOLDERS = [
  "assets/minecraft/blockstates",
  "assets/minecraft/equipment",
  "assets/minecraft/items",
  "assets/minecraft/models",
  "assets/minecraft/particles",
  "assets/minecraft/textures/block",
  "assets/minecraft/textures/effect",
  "assets/minecraft/textures/entity",
  "assets/minecraft/textures/font",
  "assets/minecraft/textures/item",
  "assets/minecraft/textures/misc",
  "assets/minecraft/textures/mob_effect",
  "assets/minecraft/textures/models",
  "assets/minecraft/textures/painting",
  "assets/minecraft/textures/particle",
  "assets/minecraft/textures/trims",
];

async function main() {
  console.log(`Downloading ${CURRENT_VERSION}.jar...`);

  const versionManifest = (await fetch(VERSION_MANIFEST_URL).then((res) =>
    res.json(),
  )) as VersionManifest;

  const versionData = versionManifest.versions.find(
    (version) => version.id == CURRENT_VERSION,
  );
  if (!versionData) {
    console.log(`Failed to find version ${CURRENT_VERSION}`);
    return;
  }

  const version = (await fetch(versionData.url).then((res) =>
    res.json(),
  )) as Version;
  if (!version) {
    console.log(`Failed to load version data for ${CURRENT_VERSION}`);
    return;
  }

  const clientJar = await JSZip.loadAsync(
    await fetch(version.downloads.client.url).then((res) => res.arrayBuffer()),
  );

  const resourcepackPath = process.argv[2];
  console.log(`Loading in resourcepack from ${resourcepackPath}`);
  const resourcepackJar = await JSZip.loadAsync(fs.readFile(resourcepackPath));

  console.log(`Merging ${CURRENT_VERSION}.jar and resourcepack`);
  const pack = new JSZip();

  for (const path in clientJar.files) {
    if (RESOURCEPACK_FOLDERS.some((folder) => path.startsWith(folder))) {
      pack.file(path, await clientJar.file(path)!.async("arraybuffer"));
    }
  }

  for (const path in resourcepackJar.files) {
    const file = await resourcepackJar.file(path);
    if (!file) {
      // Folder or invalid
      continue;
    }
    pack.file(path, file.async("arraybuffer"));
  }

  console.log("Parsing models");
  const models = await parseModels(pack);

  console.log("Generating atlas");
  const atlas = await generateAtlas(pack);

  console.log("Generating block assets");
  await generateAssets(pack, models, atlas.textureLocations);

  const resourcePath = path.parse(resourcepackPath);

  fs.writeFile(
    `./out/${resourcePath.name}-VPT-edit.zip`,
    await pack.generateAsync({ type: "nodebuffer" }),
  );
}

main();

import { mat4, vec3 } from "gl-matrix";
import type { FaceDirection, Model, Rotation } from "./Model.ts";
import type { TextureLocation } from "./Texture.ts";
import { sanitizeReference } from "./sanitization.ts";

type Face = {
  uv: [number, number, number, number];
  position: [number, number, number];
  tangent: [number, number, number];
  bitangent: [number, number, number];
  tintable: boolean;
  cutout: boolean;
};

const FACE_NORMALS = {
  up: [0, 1, 0],
  down: [0, -1, 0],
  east: [1, 0, 0],
  west: [-1, 0, 0],
  south: [0, 0, 1],
  north: [0, 0, -1],
} as const;

const RAW_FACE_POSITIONS = {
  up: {
    base: [0, 1, 1],
    posX: [1, 1, 1],
    posY: [0, 1, 0],
  },
  down: {
    base: [0, 0, 0],
    posX: [1, 0, 0],
    posY: [0, 0, 1],
  },
  east: {
    base: [1, 0, 1],
    posX: [1, 0, 0],
    posY: [1, 1, 1],
  },
  west: {
    base: [0, 0, 0],
    posX: [0, 0, 1],
    posY: [0, 1, 0],
  },
  north: {
    base: [1, 0, 0],
    posX: [0, 0, 0],
    posY: [1, 1, 0],
  },
  south: {
    base: [0, 0, 1],
    posX: [1, 0, 1],
    posY: [0, 1, 1],
  },
} as const;

export function getModelFaces(
  modelName: string,
  model: Model,
  textureLocations: Map<string, TextureLocation>,
  x?: Rotation,
  y?: Rotation,
) {
  if (!model.elements) {
    return [];
  }

  const modelTransform = mat4.identity(mat4.create());
  if (x) {
    mat4.multiply(
      modelTransform,
      mat4.fromTranslation(mat4.create(), [-0.5, -0.5, -0.5]),
      modelTransform,
    );
    mat4.multiply(
      modelTransform,
      mat4.fromXRotation(mat4.create(), -(x / 180) * Math.PI),
      modelTransform,
    );
    mat4.multiply(
      modelTransform,
      mat4.fromTranslation(mat4.create(), [0.5, 0.5, 0.5]),
      modelTransform,
    );
  }
  if (y) {
    mat4.multiply(
      modelTransform,
      mat4.fromTranslation(mat4.create(), [-0.5, -0.5, -0.5]),
      modelTransform,
    );
    mat4.multiply(
      modelTransform,
      mat4.fromYRotation(mat4.create(), -(y / 180) * Math.PI),
      modelTransform,
    );
    mat4.multiply(
      modelTransform,
      mat4.fromTranslation(mat4.create(), [0.5, 0.5, 0.5]),
      modelTransform,
    );
  }

  const faces = model.elements.flatMap((element) => {
    const elementTransform = mat4.identity(mat4.create());

    const size = vec3.create();
    vec3.sub(size, element.to, element.from);
    vec3.scale(size, size, 1.0 / 16);

    const start = vec3.scale(vec3.create(), element.from, 1.0 / 16.0);

    mat4.multiply(
      elementTransform,
      mat4.fromScaling(mat4.create(), size),
      elementTransform,
    );
    mat4.multiply(
      elementTransform,
      mat4.fromTranslation(mat4.create(), start),
      elementTransform,
    );

    if (element.rotation) {
      mat4.multiply(
        elementTransform,
        mat4.fromTranslation(
          mat4.create(),
          vec3.scale(vec3.create(), element.rotation.origin, -1 / 16),
        ),
        elementTransform,
      );
      const angle = (element.rotation.angle / 180) * Math.PI;
      let rescale = vec3.fromValues(1, 1, 1);
      let scaleAmount = 1 / Math.cos(angle);

      switch (element.rotation.axis) {
        case "x": {
          mat4.multiply(
            elementTransform,
            mat4.fromXRotation(mat4.create(), angle),
            elementTransform,
          );
          if (element.rotation.rescale) {
            rescale = vec3.fromValues(1, scaleAmount, scaleAmount);
          }
          break;
        }
        case "y": {
          mat4.multiply(
            elementTransform,
            mat4.fromYRotation(mat4.create(), -angle),
            elementTransform,
          );
          if (element.rotation.rescale) {
            rescale = vec3.fromValues(scaleAmount, 1, scaleAmount);
          }
          break;
        }
        case "z": {
          mat4.multiply(
            elementTransform,
            mat4.fromZRotation(mat4.create(), angle),
            elementTransform,
          );
          if (element.rotation.rescale) {
            rescale = vec3.fromValues(scaleAmount, scaleAmount, 1);
          }
          break;
        }
      }
      mat4.multiply(
        elementTransform,
        mat4.fromScaling(mat4.create(), rescale),
        elementTransform,
      );
      mat4.multiply(
        elementTransform,
        mat4.fromTranslation(
          mat4.create(),
          vec3.scale(vec3.create(), element.rotation.origin, 1 / 16),
        ),
        elementTransform,
      );
    }

    const elementFaces: Face[] = [];
    for (const direction in element.faces) {
      const faceDirection = direction as FaceDirection;
      const faceData = element.faces[faceDirection]!;
      const rawFacePosition = { ...RAW_FACE_POSITIONS[faceDirection] };

      const faceTransform = mat4.identity(mat4.create());
      if (faceData.rotation) {
        mat4.multiply(
          faceTransform,
          mat4.fromTranslation(mat4.create(), [-0.5, -0.5, -0.5]),
          faceTransform,
        );
        mat4.multiply(
          faceTransform,
          mat4.fromRotation(
            mat4.create(),
            -(faceData.rotation / 180) * Math.PI,
            FACE_NORMALS[faceDirection],
          ),
          faceTransform,
        );
        mat4.multiply(
          faceTransform,
          mat4.fromTranslation(mat4.create(), [0.5, 0.5, 0.5]),
          faceTransform,
        );
      }

      const totalTransform = faceTransform;
      mat4.multiply(totalTransform, elementTransform, totalTransform);
      mat4.multiply(totalTransform, modelTransform, totalTransform);

      const base = vec3.create();
      const posX = vec3.create();
      const posY = vec3.create();
      vec3.transformMat4(base, rawFacePosition.base, totalTransform);
      vec3.transformMat4(posX, rawFacePosition.posX, totalTransform);
      vec3.transformMat4(posY, rawFacePosition.posY, totalTransform);
      const tangent = vec3.sub(vec3.create(), posX, base);
      const bitangent = vec3.sub(vec3.create(), posY, base);
      if (vec3.len(tangent) < 0.001 || vec3.len(bitangent) < 0.001) {
        // Face is too small to matter
        continue;
      }

      let textureReference = faceData.texture;
      while (textureReference.startsWith("#")) {
        const textureName = model.textures[textureReference.substring(1)];
        if (!textureName) {
          console.log(
            `Texture reference "${faceData.texture}" cannot be evaluated in model "${modelName}"`,
          );
          textureReference = "block/missingno";
          break;
        }

        textureReference = textureName;
      }

      const textureLocation = textureLocations.get(
        sanitizeReference(textureReference),
      );
      if (!textureLocation) {
        if (faceData.texture != "#missingno") {
          // Special case, since this gets reported earlier
          console.log(
            `Failed to find texture reference "${faceData.texture}" in model "${modelName}"`,
          );
        }
        continue;
      }
      const uv = faceData.uv ?? [0, 0, 16, 16];

      elementFaces.push({
        position: [...base] as [number, number, number],
        tangent: [...tangent] as [number, number, number],
        bitangent: [...bitangent] as [number, number, number],
        uv: [
          textureLocation.x + textureLocation.size * (uv[0] / 16),
          textureLocation.y + textureLocation.size * (uv[3] / 16),
          textureLocation.x + textureLocation.size * (uv[2] / 16),
          textureLocation.y + textureLocation.size * (uv[1] / 16),
        ] as [number, number, number, number],
        tintable: faceData.tintindex != null,
        cutout: textureLocation.cutout,
      });
    }
    return elementFaces;
  });

  return faces;
}

export function packFace(face: Face) {
  // prettier-ignore
  const bytesPerFace = Math.ceil((
        Uint16Array.BYTES_PER_ELEMENT * 4 +  // uv
        Float32Array.BYTES_PER_ELEMENT * 3 + // position
        Float32Array.BYTES_PER_ELEMENT * 3 + // tangent
        Float32Array.BYTES_PER_ELEMENT * 3 + // bitangent
        Uint8Array.BYTES_PER_ELEMENT * 4     // tintable + cutout
    ) / 4) * 4;
  const data = new ArrayBuffer(bytesPerFace);
  const uvView = new Uint16Array(data, 0, 4);
  const positionView = new Float32Array(
    data,
    uvView.byteOffset + uvView.byteLength,
    3,
  );
  const tangentView = new Float32Array(
    data,
    positionView.byteOffset + positionView.byteLength,
    3,
  );
  const bitangentView = new Float32Array(
    data,
    tangentView.byteOffset + tangentView.byteLength,
    3,
  );
  const flagView = new Uint8Array(
    data,
    bitangentView.byteOffset + bitangentView.byteLength,
    4,
  );

  uvView.set(face.uv);
  positionView.set(face.position);
  tangentView.set(face.tangent);
  bitangentView.set(face.bitangent);
  flagView.set([(face.cutout ? 2 : 0) | (face.tintable ? 1 : 0), 0, 0, 255]);
  return new Uint8Array(data);
}

export function packModel(faces: Face[]) {
  return new Uint8Array([
    faces.length,
    0,
    0,
    255,
    ...faces.flatMap((face) => [...packFace(face)]),
  ]);
}

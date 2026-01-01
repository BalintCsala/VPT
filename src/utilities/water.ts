const GRAVITY = 9.81;

const MEDIAN_WAVE_LENGTH = 16;
const MEDIAN_AMPLITUDE = 1 / 16;

// Winds on the north hemisphere tend to go west to eastwater.
const WIND_ANGLE = 0;
// 60 degrees of maximum deviation
const MAX_ANGULAR_DEVIATION = Math.PI / 3;

const MAX_TIME = 20 * 60;
const MIN_FREQUENCY = (2 * Math.PI) / MAX_TIME;

const NUM_OF_PARAMS = 32;

function waveLengthToFrequency(waveLength: number) {
  return Math.sqrt((GRAVITY * 2 * Math.PI) / waveLength);
}

const waveParams = [];

for (let i = 0; i < NUM_OF_PARAMS; i++) {
  const waveLength = MEDIAN_WAVE_LENGTH * 2 ** (Math.random() * 15 - 10);
  const frequency =
    Math.floor(waveLengthToFrequency(waveLength) / MIN_FREQUENCY) *
    MIN_FREQUENCY;
  const waveNumber = (2 * Math.PI) / waveLength;

  const angle = WIND_ANGLE + (Math.random() * 2 - 1) * MAX_ANGULAR_DEVIATION;
  const direction = {
    x: Math.cos(angle),
    y: Math.sin(angle),
  };

  const amplitude = (MEDIAN_AMPLITUDE / MEDIAN_WAVE_LENGTH) * waveLength;

  waveParams.push({
    waveLength,
    waveNumber,
    frequency,
    direction,
    amplitude,
  });
}

waveParams.sort((p1, p2) => (p1.waveLength < p2.waveLength ? -1 : 1));

console.log("const Wave[] WAVE_PARAMS = Wave[](");
console.log(
  waveParams
    .map(
      (p) =>
        `Wave(vec2(${p.direction.x.toFixed(6)}, ${p.direction.y.toFixed(6)}), ${p.waveNumber.toFixed(6)}, ${p.frequency.toFixed(6)}, ${p.amplitude.toFixed(6)})`,
    )
    .join(",\n"),
);
console.log(");\n");

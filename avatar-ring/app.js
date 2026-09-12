'use strict';

const DEFAULT_AVATAR = 'https://avatars.githubusercontent.com/u/72215925?v=4';
const SAMPLE_SIZE = 64;
const avatar = document.querySelector('#avatar');
const preview = document.querySelector('.preview');
const status = document.querySelector('#status');
const palette = document.querySelector('#palette');
const timing = document.querySelector('#timing');
const upload = document.querySelector('#upload');
let latestRequest = 0;

const distanceSquared = (a, b) => a.reduce((sum, value, i) => sum + (value - b[i]) ** 2, 0);
const hex = color => '#' + color.map(value => Math.round(value).toString(16).padStart(2, '0')).join('').toUpperCase();

function extractPalette(image) {
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = SAMPLE_SIZE;
  const context = canvas.getContext('2d', { willReadFrequently: true });
  if (!context) throw new Error('Canvas pixel sampling is unavailable in this browser.');
  const side = Math.min(image.naturalWidth, image.naturalHeight);
  context.drawImage(image, (image.naturalWidth - side) / 2, (image.naturalHeight - side) / 2,
    side, side, 0, 0, SAMPLE_SIZE, SAMPLE_SIZE);
  const { data } = context.getImageData(0, 0, SAMPLE_SIZE, SAMPLE_SIZE);
  const points = [];
  for (let y = 0; y < SAMPLE_SIZE; y++) {
    for (let x = 0; x < SAMPLE_SIZE; x++) {
      // Sample only the circle actually visible in the avatar. Alpha weights
      // keep nearly transparent pixels from dominating a transparent logo.
      if ((x + 0.5 - 32) ** 2 + (y + 0.5 - 32) ** 2 > 32 ** 2) continue;
      const i = (y * SAMPLE_SIZE + x) * 4;
      if (data[i + 3] < 16) continue;
      points.push({ rgb: [data[i], data[i + 1], data[i + 2]], weight: data[i + 3] / 255 });
    }
  }
  if (!points.length) throw new Error('This picture is fully transparent. Try an image with visible pixels.');

  // Deterministic, farthest-first seeds followed by small weighted RGB k-means.
  // Work is bounded to a 64 × 64 sample, 8 clusters, and 12 iterations.
  const mean = [0, 0, 0];
  const total = points.reduce((sum, point) => sum + point.weight, 0);
  for (const point of points) point.rgb.forEach((value, i) => { mean[i] += value * point.weight / total; });
  const centers = [mean];
  while (centers.length < 8) {
    let best = null;
    let bestDistance = 0;
    for (const point of points) {
      const distance = Math.min(...centers.map(center => distanceSquared(point.rgb, center))) * point.weight;
      if (distance > bestDistance) { bestDistance = distance; best = point.rgb; }
    }
    if (bestDistance < 100 || !best) break;
    centers.push([...best]);
  }
  let clusters;
  for (let iteration = 0; iteration < 12; iteration++) {
    clusters = centers.map(() => ({ sum: [0, 0, 0], weight: 0 }));
    for (const point of points) {
      let nearest = 0;
      for (let i = 1; i < centers.length; i++) {
        if (distanceSquared(point.rgb, centers[i]) < distanceSquared(point.rgb, centers[nearest])) nearest = i;
      }
      const cluster = clusters[nearest];
      cluster.weight += point.weight;
      point.rgb.forEach((value, i) => { cluster.sum[i] += value * point.weight; });
    }
    clusters.forEach((cluster, i) => {
      if (cluster.weight) centers[i] = cluster.sum.map(value => value / cluster.weight);
    });
  }
  const candidates = clusters.map((cluster, i) => ({ rgb: centers[i], weight: cluster.weight }))
    .filter(cluster => cluster.weight / total >= 0.01).sort((a, b) => b.weight - a.weight);
  const chosen = [candidates.shift().rgb];
  while (chosen.length < 3 && candidates.length) {
    // Population and separation both matter. This favors substantial image
    // colors over tiny outliers, without selecting three near-identical shades.
    candidates.sort((a, b) => score(b) - score(a));
    const next = candidates.shift().rgb;
    if (Math.min(...chosen.map(color => distanceSquared(color, next))) >= 24 ** 2) chosen.push(next);
  }
  function score(candidate) {
    return Math.sqrt(candidate.weight / total) * Math.min(...chosen.map(color => distanceSquared(color, candidate.rgb)));
  }
  const distinctCount = chosen.length;
  while (chosen.length < 3) chosen.push(chosen[0]);
  return { colors: chosen.map(hex), samples: points.length, distinctCount };
}

async function loadAvatar(source, local = false) {
  const request = ++latestRequest;
  status.dataset.error = 'false';
  status.textContent = 'Loading your avatar…';
  timing.textContent = 'Waiting for an image.';
  preview.style.removeProperty('--ring-background');
  palette.replaceChildren();
  avatar.hidden = true;
  avatar.removeAttribute('src');
  document.querySelector('#placeholder').hidden = false;
  const image = new Image();
  image.crossOrigin = 'anonymous';
  let timeout;
  try {
    await new Promise((resolve, reject) => {
      timeout = setTimeout(() => reject(new Error('The image took too long to load. Try again or choose a local picture.')), 15000);
      image.onload = resolve;
      image.onerror = () => reject(new Error('Could not load the image. Check your connection or try a local picture. Remote images must allow CORS.'));
      image.src = source;
    });
    clearTimeout(timeout);
    if (request !== latestRequest) return;
    avatar.src = source;
    avatar.hidden = false;
    document.querySelector('#placeholder').hidden = true;
    status.textContent = 'Finding your colors…';
    // Give the browser a chance to paint the loaded image before sampling it.
    await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    if (request !== latestRequest) return;
    const started = performance.now();
    const result = extractPalette(image);
    const elapsed = performance.now() - started;
    const [a, b, c] = result.colors;
    preview.style.setProperty('--ring-background', `conic-gradient(from -30deg, ${a}, ${b}, ${c}, ${a})`);
    for (const color of result.colors) {
      const swatch = document.createElement('div');
      swatch.className = 'swatch';
      const chip = document.createElement('div');
      chip.className = 'swatch-color';
      chip.style.backgroundColor = color;
      const label = document.createElement('code');
      label.textContent = color;
      swatch.append(chip, label);
      palette.append(swatch);
    }
    status.textContent = result.distinctCount === 3 ? 'Your picture. Your colors.' : `${result.distinctCount} distinct ${result.distinctCount === 1 ? 'color' : 'colors'} found. Repeated to fill the ring.`;
    timing.textContent = `${result.samples.toLocaleString()} visible pixels sampled · ${elapsed.toFixed(1)} ms extraction time. Image download and decoding excluded.`;
  } catch (error) {
    if (request !== latestRequest) return;
    status.dataset.error = 'true';
    status.textContent = error.name === 'SecurityError' ? 'This image host does not allow pixel sampling. Try a local picture or a host with CORS enabled.' : error.message;
    timing.textContent = 'No palette extracted.';
  } finally {
    clearTimeout(timeout);
    // The displayed image retains its decoded content after this URL is revoked.
    if (local) URL.revokeObjectURL(source);
  }
}

upload.addEventListener('change', () => {
  const file = upload.files[0];
  if (!file) return;
  loadAvatar(URL.createObjectURL(file), true);
  upload.value = '';
});
document.querySelector('#reset').addEventListener('click', () => loadAvatar(DEFAULT_AVATAR));
document.querySelector('#width').addEventListener('input', event => {
  preview.style.setProperty('--ring-width', `${event.target.value}px`);
  document.querySelector('#width-value').value = `${event.target.value} px`;
});
for (const theme of ['light', 'dark']) {
  document.querySelector(`#${theme}`).addEventListener('click', () => {
    preview.classList.toggle('dark', theme === 'dark');
    for (const name of ['light', 'dark']) document.querySelector(`#${name}`).setAttribute('aria-pressed', String(name === theme));
  });
}
loadAvatar(DEFAULT_AVATAR);

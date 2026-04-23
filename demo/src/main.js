import { bootRuby, writeTmpFile, readTmpFile, clearTmp, runRuby } from "./ruby-runtime.js";
import { PRESETS } from "./presets.js";

const MIME_FOR_EXT = {
  jpg: "image/jpeg",
  jpeg: "image/jpeg",
  png: "image/png",
  gif: "image/gif",
  bmp: "image/bmp",
  tiff: "image/tiff",
  tif: "image/tiff",
  webp: "image/webp",
  ico: "image/x-icon"
};

const el = (id) => document.getElementById(id);

const state = {
  inputBytes: null,
  tileUrls: new Map()
};

function logLine(line, stream = "out") {
  const output = el("console-output");
  const span = document.createElement("span");
  span.className = stream === "err" ? "log-err" : "log-out";
  span.textContent = line + "\n";
  output.appendChild(span);
  output.scrollTop = output.scrollHeight;
}

function showLoading(message) {
  el("loading-message").textContent = message;
  el("loading-overlay").classList.remove("hidden");
}

function hideLoading() {
  el("loading-overlay").classList.add("hidden");
}

// Ruby source that generates a colourful RGB gradient 400x300 JPEG at /tmp/input.jpg.
// We let pura-image itself produce the demo's seed image so the repo ships no binary
// blob, and so the landing page can show the full pipeline (encode ⇒ decode ⇒
// transform ⇒ re-encode) before the user has to do anything.
const SAMPLE_GEN_RUBY = `
require "pura-image"

w, h = 400, 300
pixels = String.new
h.times do |y|
  w.times do |x|
    r = (x * 255 / (w - 1))
    g = (y * 255 / (h - 1))
    b = ((w - 1 - x) * 255 / (w - 1))
    pixels << [r, g, b].pack("CCC")
  end
end
pixels.force_encoding(Encoding::BINARY)
wrapper = Pura::Image::Wrapper.new(w, h, pixels)
Pura::Image.save(wrapper, "/tmp/input.jpg", quality: 85)
`;

function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// Highlight a small subset of Ruby tokens for the preset code display.
// We don't need a full parser — this is strictly cosmetic.
function highlightRuby(code) {
  const escaped = escapeHtml(code);
  return escaped
    .replace(/(^|\n)(#[^\n]*)/g, (_, nl, c) => `${nl}<span class="cm-cm">${c}</span>`)
    .replace(/"([^"\n]*)"/g, '<span class="cm-str">&quot;$1&quot;</span>')
    .replace(/\b(require|do|end|begin|rescue|if|else)\b/g, '<span class="cm-kw">$1</span>')
    .replace(/\b(ImageProcessing|Pura)\b/g, '<span class="cm-cls">$1</span>')
    .replace(/\b(\d+)\b/g, '<span class="cm-num">$1</span>');
}

function createTile(preset) {
  const tile = document.createElement("article");
  tile.className = "tile";
  tile.dataset.preset = preset.id;
  tile.innerHTML = `
    <header class="tile-header">
      <h3>${escapeHtml(preset.label)}</h3>
      <span class="tile-status" data-role="status">queued</span>
    </header>
    <div class="tile-image" data-role="image">
      <span class="tile-placeholder">waiting&hellip;</span>
    </div>
    <p class="tile-meta" data-role="meta"></p>
    <details class="tile-details">
      <summary>Ruby</summary>
      <pre class="tile-code"><code>${highlightRuby(preset.code.trim())}</code></pre>
    </details>
    <details class="tile-details">
      <summary>Rails variant</summary>
      <pre><code>${escapeHtml(preset.railsSnippet)}</code></pre>
      <button type="button" data-role="copy-rails">Copy</button>
    </details>
  `;

  tile.querySelector("[data-role=copy-rails]").addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(preset.railsSnippet);
      const btn = tile.querySelector("[data-role=copy-rails]");
      btn.textContent = "Copied!";
      setTimeout(() => (btn.textContent = "Copy"), 1200);
    } catch (err) {
      logLine(`Clipboard error: ${err.message}`, "err");
    }
  });

  return tile;
}

function populateTiles() {
  const container = el("tiles");
  container.innerHTML = "";
  for (const preset of PRESETS) {
    container.appendChild(createTile(preset));
  }
}

function setTileStatus(presetId, text, className) {
  const tile = document.querySelector(`.tile[data-preset="${presetId}"]`);
  if (!tile) return;
  const status = tile.querySelector("[data-role=status]");
  status.textContent = text;
  status.className = `tile-status ${className ?? ""}`;
}

// No mainstream browser renders TIFF via <img>, so we skip the preview for that
// format and show the byte count instead. The bytes are still real — the
// Download link saves a valid TIFF you can open in any image viewer.
const NON_PREVIEWABLE = new Set(["tiff", "tif"]);

function setTileOutput(presetId, bytes, elapsed, ext) {
  const tile = document.querySelector(`.tile[data-preset="${presetId}"]`);
  if (!tile) return;
  const imageSlot = tile.querySelector("[data-role=image]");
  const meta = tile.querySelector("[data-role=meta]");

  const mime = MIME_FOR_EXT[ext] ?? "application/octet-stream";
  const blob = new Blob([bytes], { type: mime });
  const url = URL.createObjectURL(blob);

  const prevUrl = state.tileUrls.get(presetId);
  if (prevUrl) URL.revokeObjectURL(prevUrl);
  state.tileUrls.set(presetId, url);

  const previewHtml = NON_PREVIEWABLE.has(ext)
    ? `<span class="tile-format-badge">.${ext}</span>
       <span class="tile-placeholder">Browsers don't render ${ext.toUpperCase()} — the file is valid, download to open it.</span>`
    : `<img src="${url}" alt="${escapeHtml(presetId)} output" />`;

  imageSlot.innerHTML = `
    ${previewHtml}
    <a class="tile-download" href="${url}" download="output.${ext}">Download .${ext}</a>
  `;
  meta.textContent = `${(bytes.byteLength / 1024).toFixed(1)} KB · ${elapsed}ms`;
}

function setTileError(presetId, message) {
  const tile = document.querySelector(`.tile[data-preset="${presetId}"]`);
  if (!tile) return;
  tile.querySelector("[data-role=image]").innerHTML =
    `<span class="tile-error">${escapeHtml(message)}</span>`;
  tile.querySelector("[data-role=meta]").textContent = "";
}

async function runOnePreset(preset) {
  setTileStatus(preset.id, "running", "status-running");
  const outputName = `output.${preset.outputExt}`;

  // Remove any stale output from previous runs so we don't misread it as success.
  try {
    clearTmp();
  } catch (_) {
    // clearTmp is safe to call even before first run
  }
  writeTmpFile("input.jpg", state.inputBytes);

  const started = performance.now();
  const result = runRuby(preset.code);
  const elapsed = (performance.now() - started).toFixed(0);

  if (!result.ok) {
    logLine(`[${preset.id}] failed: ${result.error}`, "err");
    setTileStatus(preset.id, "error", "status-error");
    setTileError(preset.id, "Ruby raised — see console");
    return;
  }
  const bytes = readTmpFile(outputName);
  if (!bytes) {
    logLine(`[${preset.id}] ok but no /tmp/${outputName} produced`, "err");
    setTileStatus(preset.id, "no output", "status-error");
    setTileError(preset.id, "No output file");
    return;
  }
  logLine(`[${preset.id}] ${bytes.byteLength} bytes (${outputName}) in ${elapsed}ms`, "out");
  setTileStatus(preset.id, `${elapsed}ms`, "status-ok");
  setTileOutput(preset.id, bytes, elapsed, preset.outputExt);
}

async function runAllPresets() {
  for (const preset of PRESETS) {
    setTileStatus(preset.id, "queued", "");
  }
  for (const preset of PRESETS) {
    await runOnePreset(preset);
    // Yield so the browser can paint each tile as it completes.
    await new Promise((r) => setTimeout(r, 0));
  }
}

async function seedSampleImage() {
  logLine("Generating 400x300 gradient sample via pura-image…", "out");
  const started = performance.now();
  const result = runRuby(SAMPLE_GEN_RUBY);
  if (!result.ok) {
    logLine(`Could not generate sample: ${result.error}`, "err");
    return false;
  }
  const bytes = readTmpFile("input.jpg");
  if (!bytes) {
    logLine("Sample generation ran but produced no /tmp/input.jpg", "err");
    return false;
  }
  state.inputBytes = bytes;
  const blob = new Blob([bytes], { type: "image/jpeg" });
  const url = URL.createObjectURL(blob);
  el("input-preview").src = url;
  el("input-meta").textContent =
    `gradient.jpg · 400x300 · ${(bytes.byteLength / 1024).toFixed(1)} KB · generated in ${(performance.now() - started).toFixed(0)}ms`;
  return true;
}

async function handleUserFile(file) {
  const buffer = await file.arrayBuffer();
  state.inputBytes = new Uint8Array(buffer);
  const blob = new Blob([state.inputBytes], { type: file.type || "application/octet-stream" });
  el("input-preview").src = URL.createObjectURL(blob);
  el("input-meta").textContent =
    `${file.name} · ${(state.inputBytes.byteLength / 1024).toFixed(1)} KB · your file`;
  logLine(`Loaded user file: ${file.name} (${state.inputBytes.byteLength} bytes). Re-running presets…`, "out");
  await runAllPresets();
}

function setupFileInput() {
  const input = el("file-input");
  el("pick-file").addEventListener("click", () => input.click());
  input.addEventListener("change", (e) => {
    const file = e.target.files?.[0];
    if (file) handleUserFile(file);
  });

  // Allow dropping anywhere on the page.
  ["dragenter", "dragover"].forEach((evt) =>
    document.addEventListener(evt, (e) => {
      e.preventDefault();
      document.body.classList.add("dragging");
    })
  );
  ["dragleave", "drop"].forEach((evt) =>
    document.addEventListener(evt, (e) => {
      e.preventDefault();
      if (evt === "drop" || e.target === document.documentElement) {
        document.body.classList.remove("dragging");
      }
    })
  );
  document.addEventListener("drop", (e) => {
    const file = e.dataTransfer?.files?.[0];
    if (file) handleUserFile(file);
  });
}

function setupConsole() {
  el("clear-console").addEventListener("click", () => (el("console-output").textContent = ""));
}

async function main() {
  populateTiles();
  setupFileInput();
  setupConsole();

  showLoading("Fetching ruby.wasm…");
  try {
    await bootRuby("./ruby.wasm", logLine, showLoading);
  } catch (err) {
    showLoading(`Failed to boot ruby.wasm: ${err.message}`);
    console.error(err);
    return;
  }
  hideLoading();
  logLine("ruby.wasm ready.", "out");

  if (await seedSampleImage()) {
    await runAllPresets();
    logLine("All presets complete.", "out");
  }
}

main();

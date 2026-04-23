import { RubyVM } from "@ruby/wasm-wasi";
import {
  WASI,
  File,
  OpenFile,
  ConsoleStdout,
  PreopenDirectory
} from "@bjorn3/browser_wasi_shim";

// Singleton state: we only boot Ruby once per page load.
let tmpDir = null;
let vm = null;
let consoleSink = null;

/**
 * Boot ruby.wasm and wire up a WASI virtual /tmp directory.
 *
 * @param {string} wasmUrl URL the fetch() call will hit for the wasm binary.
 * @param {(line: string, stream: "out"|"err") => void} onLog  called for each line Ruby writes to stdout/stderr.
 * @param {(stage: string) => void} onStage  UI progress callback.
 */
export async function bootRuby(wasmUrl, onLog, onStage) {
  if (vm) return { vm, tmpDir };
  consoleSink = onLog;

  onStage?.("Fetching ruby.wasm...");
  const response = await fetch(wasmUrl);
  if (!response.ok) throw new Error(`Failed to fetch ${wasmUrl}: ${response.status}`);
  const bytes = await response.arrayBuffer();

  onStage?.("Compiling WebAssembly...");
  const mod = await WebAssembly.compile(bytes);

  onStage?.("Initializing Ruby VM...");
  tmpDir = new PreopenDirectory("/tmp", new Map());

  const fds = [
    new OpenFile(new File([])),
    ConsoleStdout.lineBuffered((line) => consoleSink?.(line, "out")),
    ConsoleStdout.lineBuffered((line) => consoleSink?.(line, "err")),
    tmpDir
  ];
  const wasi = new WASI(["ruby.wasm"], [], fds, { debug: false });

  vm = new RubyVM();
  const imports = { wasi_snapshot_preview1: wasi.wasiImport };
  vm.addToImports(imports);

  const instance = await WebAssembly.instantiate(mod, imports);
  await vm.setInstance(instance);
  wasi.initialize(instance);
  vm.initialize(["ruby.wasm", "-EUTF-8", "-e_=0"]);

  return { vm, tmpDir };
}

/**
 * Overwrite /tmp/<name> with the given bytes. If a file with the same name
 * already exists, it is replaced.
 */
export function writeTmpFile(name, uint8Array) {
  if (!tmpDir) throw new Error("Ruby VM not booted");
  tmpDir.dir.contents.set(name, new File(uint8Array));
}

/**
 * Read /tmp/<name> back into a Uint8Array, or return null if the file was
 * never created by the Ruby code.
 */
export function readTmpFile(name) {
  if (!tmpDir) return null;
  const entry = tmpDir.dir.contents.get(name);
  if (!entry) return null;
  // browser_wasi_shim's File exposes the raw bytes as `.data` (Uint8Array).
  return entry.data;
}

/**
 * Delete every file in /tmp so successive Runs don't leak state (and so
 * a previous Run's output isn't mistaken for this Run's output).
 */
export function clearTmp() {
  if (!tmpDir) return;
  tmpDir.dir.contents.clear();
}

/**
 * Execute Ruby source. Returns `{ ok, error }`. stdout/stderr are streamed to
 * the onLog callback that was passed to bootRuby.
 */
export function runRuby(source) {
  if (!vm) throw new Error("Ruby VM not booted");
  const wrapped = `
    begin
      ${source}
      :__pura_demo_ok__
    rescue Exception => e
      $stderr.puts(e.full_message(highlight: false))
      :__pura_demo_error__
    end
  `;
  try {
    const result = vm.eval(wrapped);
    const ok = result.toString() === "__pura_demo_ok__";
    return { ok, error: ok ? null : "Ruby raised an exception (see console)." };
  } catch (err) {
    return { ok: false, error: err?.message ?? String(err) };
  }
}

# pura-image Playground (ruby.wasm demo)

A single-page demo that runs **pura-image directly in the browser** via ruby.wasm. Land on the page and you see the full spread at a glance: an auto-generated 400x300 gradient input image (produced by pura-image itself — no bundled binaries) and all six preset transformations already executed on it. Drop your own image to re-run everything with it.

What's running is the `ImageProcessing::Pura` chainable API plus the pura-* format gems — no libvips, no ImageMagick, no C extensions.

## Why this demo exists

Browser JavaScript can resize and crop images with Canvas, but it cannot run `ImageProcessing::Pura.source(...).resize_to_limit(...).convert(...).call` — that chain only exists in the Ruby ecosystem. This demo exists to demonstrate:

1. pura-image's "zero dependency" claim is real enough to survive in a wasm sandbox
2. `ImageProcessing::Pura` chains run identically here as anywhere else Ruby runs — no browser-specific branches
3. Formats that pure-JS cannot easily encode (TIFF, ICO) become trivial in Ruby

## Local development

### Prerequisites

- Ruby 3.4 (pinned in [.tool-versions](./.tool-versions))
- Node.js 22

Both are auto-selected by [mise](https://mise.jdx.dev/) if you have it installed.

### One-time setup

```bash
cd demo/build
bundle install        # installs ruby_wasm (rbwasm CLI) + pura-image for bundling

cd ..
npm install           # installs Vite + CodeMirror + @ruby/wasm-wasi
```

### Building the wasm binary

```bash
npm run build:wasm
```

This invokes `rbwasm build` inside `demo/build/` and writes the result to `demo/public/ruby.wasm` (~47 MB, ~15 MB gzipped). It bundles:

- `pura-image` 0.3 + all `pura-*` format gems (jpeg, png, bmp, gif, tiff, ico, webp)
- `pura-processing` (the pure-Ruby `image_processing` base that replaced the ruby-vips/mini_magick dep chain)
- `js` gem (presence of `js` in the bundle is what tells rbwasm to produce a **reactor-style** wasm with the Ruby ABI exports that `@ruby/wasm-wasi`'s `RubyVM` expects — without it you get a command-style wasm and RubyVM.setInstance fails with `FinalizationRegistry: cleanup must be callable`)

### Running the dev server

```bash
npm run dev
```

Then open http://localhost:5173.

### Production build

```bash
npm run build && npm run preview
```

Vite outputs to `dist/` (includes `ruby.wasm` copied from `public/`).

## How it works

1. **JS → wasm virtual filesystem**: dropped image bytes are written to `/tmp/input.<ext>` inside a `PreopenDirectory` from `@bjorn3/browser_wasi_shim`.
2. **Ruby runs unchanged**: the user's snippet calls `ImageProcessing::Pura.source("/tmp/input.jpg")...call(destination: "/tmp/output.png")`. pura-image uses `File.binread`, which works against the virtual FS.
3. **wasm → JS**: the output bytes are read back from the same `PreopenDirectory`, wrapped in a `Blob`, and shown in `<img>` + offered for download.

Key files:

- [`src/ruby-runtime.js`](./src/ruby-runtime.js) — WASI FS bridge + RubyVM boot
- [`src/main.js`](./src/main.js) — grid rendering + runAllPresets orchestration + Ruby-side sample image generation
- [`src/presets.js`](./src/presets.js) — the 6 preset snippets (resize, format convert, rotate+grayscale, TIFF encode, ICO favicon, WebP)
- [`build/Gemfile`](./build/Gemfile) — which gems go into the wasm

## Deployment

Pushes to `main` that touch `demo/**` or the workflow file itself trigger [`.github/workflows/demo-deploy.yml`](../.github/workflows/demo-deploy.yml), which rebuilds the wasm on clean Ubuntu runners and publishes the `dist/` output to GitHub Pages.

## Limitations to be honest about

- First visit downloads a ~47 MB wasm (gzipped ~15 MB). We show a loading overlay so users aren't left staring at a blank screen.
- No YJIT in wasm, so Ruby code is slower than on CRuby. The 400x300 sample completes every preset in 1–4 seconds the first time (cold gem require), and noticeably faster on subsequent runs.
- `PreopenDirectory` keeps files in memory; converting very large images is bounded by the tab's heap.
- The TIFF tile shows a file badge rather than a preview — mainstream browsers can't render TIFF natively, but the downloaded file is a valid TIFF. The WebP and ICO tiles render because browsers do support those.

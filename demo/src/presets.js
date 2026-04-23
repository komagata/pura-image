// Preset Ruby snippets that read /tmp/input.jpg and write /tmp/output.<ext>.
//
// The playground always writes the dropped image to /tmp/input.jpg regardless
// of its real format — pura-image detects format by magic bytes, so the
// extension is cosmetic. Keeping the path literal in the editor means the
// snippet can be copy-pasted into a Rails app without search-and-replace.
//
// Each entry has:
//   - label:        shown in the <select> dropdown
//   - outputExt:    extension the Ruby snippet writes to (used to read back bytes)
//   - code:         the Ruby source displayed in the editor
//   - railsSnippet: equivalent Active Storage variant definition for the "Copy as Rails variant" section

export const PRESETS = [
  {
    id: "resize_to_limit",
    label: "resize_to_limit(400, 400)",
    outputExt: "jpg",
    code: `require "image_processing/pura"

ImageProcessing::Pura
  .source("/tmp/input.jpg")
  .resize_to_limit(400, 400)
  .call(destination: "/tmp/output.jpg")
`,
    railsSnippet: `has_one_attached :photo do |attachable|
  attachable.variant :thumb, resize_to_limit: [400, 400]
end`
  },
  {
    id: "resize_to_fill_png",
    label: "resize_to_fill(300, 300) + convert PNG",
    outputExt: "png",
    code: `require "image_processing/pura"

ImageProcessing::Pura
  .source("/tmp/input.jpg")
  .resize_to_fill(300, 300)
  .convert("png")
  .call(destination: "/tmp/output.png")
`,
    railsSnippet: `has_one_attached :photo do |attachable|
  attachable.variant :square, resize_to_fill: [300, 300], format: :png
end`
  },
  {
    id: "rotate_grayscale",
    label: "rotate(90).grayscale chain",
    outputExt: "jpg",
    code: `require "image_processing/pura"

ImageProcessing::Pura
  .source("/tmp/input.jpg")
  .rotate(90)
  .colourspace("b-w")
  .call(destination: "/tmp/output.jpg")
`,
    railsSnippet: `has_one_attached :photo do |attachable|
  attachable.variant :stylised, rotate: 90, colourspace: "b-w"
end`
  },
  {
    id: "encode_tiff",
    label: "→ TIFF",
    outputExt: "tiff",
    code: `# Browser JavaScript has no TIFF encoder. pura-tiff does it in pure Ruby.
require "image_processing/pura"

ImageProcessing::Pura
  .source("/tmp/input.jpg")
  .resize_to_limit(800, 800)
  .convert("tiff")
  .call(destination: "/tmp/output.tiff")
`,
    railsSnippet: `has_one_attached :scan do |attachable|
  attachable.variant :archival, resize_to_limit: [800, 800], format: :tiff
end`
  },
  {
    id: "favicon_ico",
    label: "→ .ico",
    outputExt: "ico",
    code: `# pura-ico encodes favicons entirely in Ruby.
require "image_processing/pura"

ImageProcessing::Pura
  .source("/tmp/input.jpg")
  .resize_to_fill(64, 64)
  .convert("ico")
  .call(destination: "/tmp/output.ico")
`,
    railsSnippet: `has_one_attached :brand_icon do |attachable|
  attachable.variant :favicon, resize_to_fill: [64, 64], format: :ico
end`
  },
  {
    id: "convert_webp",
    label: "→ WebP",
    outputExt: "webp",
    code: `require "image_processing/pura"

ImageProcessing::Pura
  .source("/tmp/input.jpg")
  .resize_to_limit(400, 400)
  .convert("webp")
  .call(destination: "/tmp/output.webp")
`,
    railsSnippet: `has_one_attached :photo do |attachable|
  attachable.variant :modern, resize_to_limit: [400, 400], format: :webp
end`
  }
];

export function findPreset(id) {
  return PRESETS.find((p) => p.id === id) ?? PRESETS[0];
}

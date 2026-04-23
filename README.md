# pura-image

Pure Ruby image processing library with **zero C extension dependencies**. Bundles all **pura-*** format gems and provides an `ImageProcessing` adapter for Rails Active Storage.

## Why this exists (in 30 seconds)

Stop installing system libraries just to resize an image in Rails.

```diff
# Gemfile
+ gem "pura-image"
```

```ruby
# config/application.rb
config.active_storage.variant_processor = :pura
```

```diff
# Dockerfile
- RUN apt-get install -y libvips-dev imagemagick
```

That's it. No `brew install vips`. No `apt install imagemagick`. No C compiler. Works on macOS, Linux, Windows, Docker, CI, ruby.wasm — anywhere Ruby runs.

- ✅ **Drop-in** for `ImageProcessing::Vips` / `ImageProcessing::MiniMagick`
- ✅ **7 formats** — JPEG, PNG, BMP, GIF, TIFF, ICO/CUR, WebP
- ✅ **Some operations are faster than C** (no process-spawn overhead — see [Benchmark](#benchmark))
- ✅ **Runs on ruby.wasm, JRuby, TruffleRuby** — [try it in your browser](./demo) (no server, no upload)

## Supported Formats

| Format | Decode | Encode | Gem |
|--------|--------|--------|-----|
| JPEG | ✅ | ✅ | [pura-jpeg](https://github.com/komagata/pura-jpeg) |
| PNG | ✅ | ✅ | [pura-png](https://github.com/komagata/pura-png) |
| BMP | ✅ | ✅ | [pura-bmp](https://github.com/komagata/pura-bmp) |
| GIF | ✅ | ✅ | [pura-gif](https://github.com/komagata/pura-gif) |
| TIFF | ✅ | ✅ | [pura-tiff](https://github.com/komagata/pura-tiff) |
| ICO/CUR | ✅ | ✅ | [pura-ico](https://github.com/komagata/pura-ico) |
| WebP | ✅ | ✅ | [pura-webp](https://github.com/komagata/pura-webp) |

Format auto-detection by magic bytes — no extension guessing needed for decode.

## Try it in your browser

The [Rails Active Storage Playground](./demo) runs the exact `ImageProcessing::Pura` chain you would put in your Rails model — in your browser tab, via ruby.wasm. Drop an image, edit the Ruby code, hit Run. Your image never leaves the page.

Bonus: two formats that browser JavaScript cannot encode natively — **TIFF** and **ICO** — are a one-liner in pura-image. See [demo/README.md](./demo/README.md) for local setup, or visit the deployed page (link in the repo's Pages settings).

## Installation

```bash
gem install pura-image
```

## Usage

```ruby
require "pura-image"

# Load any format (auto-detected from magic bytes)
image = Pura::Image.load("photo.jpg")
image = Pura::Image.load("logo.png")
image.width   #=> 800
image.height  #=> 600

# Save to any format (detected from extension)
Pura::Image.save(image, "output.png")

# Convert between formats
Pura::Image.convert("input.bmp", "output.jpg", quality: 85)
Pura::Image.convert("photo.tiff", "photo.png")
```

## Image Operations

All operations from the `image_processing` gem are supported:

```ruby
image = Pura::Image.load("photo.jpg")

# Resize
image.resize_to_limit(800, 600)   # downsize only, keep aspect ratio
image.resize_to_fit(400, 400)     # resize to fit, keep aspect ratio
image.resize_to_fill(400, 400)    # fill exact size, center crop excess
image.resize_and_pad(400, 400)    # fit within bounds, pad with black
image.resize_to_cover(400, 400)   # cover bounds, no crop

# Transform
image.crop(10, 10, 200, 200)      # crop region
image.rotate(90)                   # rotate 90/180/270 degrees
image.grayscale                    # convert to grayscale

# Chain operations
result = Pura::Image.load("photo.jpg")
  .resize_to_limit(800, 600)
  .rotate(90)
  .grayscale

Pura::Image.save(result, "thumb.jpg", quality: 80)
```

## Rails Active Storage Integration

Drop-in replacement for libvips/ImageMagick:

```ruby
# Gemfile
gem "pura-image"

# config/application.rb
config.active_storage.variant_processor = :pura
```

Models and views stay exactly the same:

```ruby
class User < ApplicationRecord
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
  end
end
```

```erb
<%= image_tag user.avatar.variant(:thumb) %>
```

No `brew install vips`. No `apt install imagemagick`. Just `gem install` and go.

### ImageProcessing::Pura API

```ruby
require "image_processing/pura"

# Same API as ImageProcessing::Vips
processed = ImageProcessing::Pura
  .source("photo.jpg")
  .resize_to_limit(400, 400)
  .convert("png")
  .call(destination: "output.png")

# Pipeline branching
pipeline = ImageProcessing::Pura.source("photo.jpg")
large  = pipeline.resize_to_limit(800, 800).call(destination: "large.jpg")
medium = pipeline.resize_to_limit(500, 500).call(destination: "medium.jpg")
small  = pipeline.resize_to_limit(300, 300).call(destination: "small.jpg")

# Validation
ImageProcessing::Pura.valid_image?("photo.jpg")  #=> true
```

## Benchmark

400×400 image, Ruby 4.0.2 + YJIT vs ffmpeg (C + SIMD).

### Decode

| Format | pura-* | ffmpeg | vs ffmpeg |
|--------|--------|--------|-----------|
| TIFF | **14 ms** | 59 ms | 🚀 **4× faster** |
| BMP | **39 ms** | 59 ms | 🚀 **1.5× faster** |
| GIF | 77 ms | 65 ms | ~1× (comparable) |
| PNG | 111 ms | 60 ms | 1.9× slower |
| JPEG | 304 ms | 55 ms | 5.5× slower |

### Encode

| Format | pura-* | ffmpeg | vs ffmpeg |
|--------|--------|--------|-----------|
| TIFF | **0.8 ms** | 58 ms | 🚀 **73× faster** |
| BMP | **35 ms** | 58 ms | 🚀 **1.7× faster** |
| PNG | **52 ms** | 61 ms | 🚀 **faster** |
| JPEG | 238 ms | 62 ms | 3.8× slower |
| GIF | 377 ms | 59 ms | 6.4× slower |

5 out of 11 operations are **faster than C** (ffmpeg process-spawn overhead).

## Why pure Ruby?

- **`gem install` and go** — no `brew install`, no `apt install`, no C compiler
- **Works everywhere Ruby works** — CRuby, ruby.wasm, mruby, JRuby, TruffleRuby
- **Edge/Wasm ready** — browsers (ruby.wasm), sandboxed environments, no system libraries needed
- **Perfect for dev/CI** — no ImageMagick/libvips setup. `rails new` → image upload → it just works
- **7 formats, 1 interface** — unified API across JPEG, PNG, BMP, GIF, TIFF, ICO, WebP

## License

MIT

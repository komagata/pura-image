# pura-image

Pure Ruby image processing library. Bundles all **pura-*** format gems for unified image loading, saving, and conversion.

Part of the **pura-*** series — pure Ruby image codec gems.

## Supported Formats

| Format | Decode | Encode | Gem |
|--------|--------|--------|-----|
| JPEG | ✅ | ✅ | [pura-jpeg](https://github.com/komagata/pura-jpeg) |
| PNG | ✅ | ✅ | [pura-png](https://github.com/komagata/pura-png) |
| BMP | ✅ | ✅ | [pura-bmp](https://github.com/komagata/pura-bmp) |
| GIF | ✅ | ✅ | [pura-gif](https://github.com/komagata/pura-gif) |
| TIFF | ✅ | ✅ | [pura-tiff](https://github.com/komagata/pura-tiff) |
| ICO | ✅ | ✅ | [pura-ico](https://github.com/komagata/pura-ico) |
| WebP | ✅ | ✅ (lossless) | [pura-webp](https://github.com/komagata/pura-webp) |

## Installation

```bash
gem install pura-image
```

## Usage

```ruby
require "pura-image"

# Load any supported format (auto-detected)
image = Pura::Image.load("photo.jpg")

# Resize
result = image.resize_to_fit(400, 400)

# Save to any format (auto-detected from extension)
Pura::Image.save(result, "output.png")

# Convert between formats
Pura::Image.convert("input.webp", "output.jpg")

# Check supported formats
Pura::Image.supported_formats #=> [:jpeg, :png, :bmp, :gif, :tiff, :ico, :webp]
```

### Active Storage Integration

```ruby
# config/environments/production.rb
config.active_storage.variant_processor = :pura

# In your model
class User < ApplicationRecord
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fit: [100, 100]
  end
end
```

## Benchmark Summary

400×400 image, Ruby 4.0.2 + YJIT.

### Decode

| Format | pura-* | ffmpeg (C) | vs ffmpeg |
|--------|--------|------------|-----------|
| JPEG | 304 ms | 55 ms | 5.5× |
| PNG | 111 ms | 60 ms | 1.9× |
| BMP | 39 ms | 59 ms | **0.7× (faster!)** |
| GIF | 77 ms | 65 ms | **1.2×** |
| TIFF | 14 ms | 59 ms | **0.2× (4× faster!)** |
| WebP | 207 ms | 66 ms | 3.1× |

### Encode

| Format | pura-* | ffmpeg (C) | vs ffmpeg |
|--------|--------|------------|-----------|
| JPEG | 238 ms | 62 ms | 3.8× |
| PNG | 52 ms | 61 ms | **0.8× (faster!)** |
| BMP | 35 ms | 58 ms | **0.6× (faster!)** |
| GIF | 377 ms | 59 ms | 6.4× (includes color quantization) |
| TIFF | 0.8 ms | 58 ms | **0.01× (73× faster!)** |

## Why pure Ruby?

- **`gem install` and go** — no `brew install`, no `apt install`, no C compiler needed
- **Works everywhere Ruby works** — CRuby, ruby.wasm, JRuby, TruffleRuby
- **Perfect for dev/CI** — no ImageMagick or libvips setup
- **Three formats beat ffmpeg** — BMP, GIF, and TIFF decode faster than C

## License

MIT

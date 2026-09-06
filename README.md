# pura-image

Image processing in Ruby, without installing libvips or ImageMagick. Bundles the **pura-*** codec gems and provides a pipeline API and Rails Active Storage integration.

## Installation

```ruby
# Gemfile
gem "pura-image"

# config/application.rb
config.active_storage.variant_processor = :pura
```

The adapter does not require `image_processing`, `ruby-vips`, or `mini_magick`. Remove `image_processing` from your Gemfile if nothing else uses it. Requiring pura-image does not change your processor setting; select `:pura` explicitly.

The codecs are written in Ruby. PNG compression uses Ruby's standard `zlib` library, which must be available in your Ruby runtime. No additional image library or image-specific native extension needs to be installed.

## Supported formats and limitations

All decoded images currently use **8-bit RGB** pixels. Alpha, color profiles, EXIF metadata, and animation are not preserved. This matters for transparent logos and photographs whose orientation is stored in EXIF; pura-image does not yet auto-orient them.

| Format | Decode | Encode | Limitations |
|--------|--------|--------|-------------|
| JPEG | Baseline | Baseline | No progressive JPEG or EXIF orientation correction |
| PNG | Non-interlaced | RGB | No Adam7; alpha/tRNS discarded; 16-bit input reduced to 8-bit |
| BMP | Supported by pura-bmp | 24-bit RGB | Alpha is not preserved |
| GIF | First image | Single image | Animation is not preserved; transparent pixels are flattened |
| TIFF | 8-bit strips: uncompressed, LZW, PackBits | Uncompressed | First IFD only; alpha is discarded |
| ICO | BMP/PNG entries | PNG entries | Alpha is not preserved |
| CUR | Read through pura-ico | Not supported | Saving `.cur` raises `ArgumentError` |
| WebP | VP8 lossy | VP8L lossless | No VP8L/VP8X decode; **encoded WebP cannot be read back by pura-webp yet** |

See each [pura-* codec repository](https://github.com/komagata?tab=repositories&q=pura-) for its detailed restrictions. WebP also lacks the VP8 loop filter and multi-partition frame support. Format detection uses magic bytes; output format comes from the destination extension.

## Usage

```ruby
require "pura-image"

image = Pura::Image.load("photo.jpg")
thumb = image.resize_to_limit(800, 600).rotate(90).grayscale
Pura::Image.save(thumb, "thumb.png", compression: 6)
Pura::Image.convert("photo.bmp", "photo.jpg", quality: 85)
```

Operations return a new image:

| Operation | Behavior |
|-----------|----------|
| `resize_to_limit(w, h)` | Fit without enlarging |
| `resize_to_fit(w, h)` | Fit, allowing enlargement |
| `resize_to_fill(w, h)` | Fill, then center-crop |
| `resize_to_cover(w, h)` | Cover without cropping |
| `resize_and_pad(w, h, background: [0, 0, 0])` | Fit and center on an RGB background |
| `crop(x, y, w, h)` | Crop a positive integer region entirely inside the image |
| `rotate(degrees)` | Multiples of 90 degrees only |
| `grayscale` | Convert RGB to equal channels |
| `strip` | Return a copy; the current image model already discards metadata |

`resize_to_limit` and `resize_to_fit` accept one `nil` dimension to leave that side unbounded. Supply at least one positive integer dimension. For example, `resize_to_fit(400, nil)` resizes to width 400 while preserving aspect ratio.

These are a subset of the operations available in Vips/ImageMagick. Unsupported keyword options, such as `gravity:`, raise `ArgumentError`; they are not silently ignored. Saver options are passed to the selected codec: JPEG supports `quality:` and `subsampling:`, PNG supports `compression:`, and GIF supports `max_colors:`.

## Pipeline API

```ruby
require "image_processing/pura"

pipeline = ImageProcessing::Pura.source("photo.jpg")
pipeline.resize_to_limit(400, nil).convert("png").call(destination: "thumb.png")
pipeline.resize_to_limit(100, 100).call(destination: "small.jpg")

ImageProcessing::Pura.valid_image?("photo.jpg") # true when this backend can decode it
```

The chainable API is provided by [pura-processing](https://github.com/komagata/pura-processing), adapted from `image_processing` under the MIT license. Only `loader(page: 0)` is supported; other pages and unknown loader options are rejected.

## Rails Active Storage

With the processor configuration above, use ordinary variants:

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

The dedicated transformer handles supported image variants without the `image_processing` gem. This does not provide PDF/video previewers or a metadata analyzer. Image format and operation limitations above also apply to Rails variants.

The integration CI exercises a real upload and variant generation on Rails 7.2, 8.0, and 8.1, with eager loading both enabled and disabled, and checks that `:disabled` is left unchanged.

## Browser demo

The [ruby.wasm demo](https://komagata.github.io/pura-image/) runs transformations in the browser. See [demo/README.md](demo/README.md). Runtime support depends on the Ruby version and available standard libraries; CRuby CI results should not be read as verification of every alternative Ruby implementation.

## Performance

The earlier 400×400 benchmark compared Ruby 4.0.2 + YJIT to a new ffmpeg process for every operation. Its measurements include ffmpeg process startup and do not establish that the codec is faster than an in-process C library such as libvips.

For Rails deployment decisions, measure the complete decode–resize–encode pipeline with your own photographs, and compare output quality, file size, latency, and peak memory under the same settings. pura-image prioritizes installation convenience; native codecs are usually the appropriate comparison for throughput-sensitive workloads.

## License

MIT

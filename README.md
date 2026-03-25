# Pura::Image

Pure Ruby image processing library that bundles pura-jpeg and pura-png.

## Installation

```ruby
gem "pura-image"
```

## Usage

```ruby
require "pura-image"

image = Pura::Image.load("photo.jpg")
result = image.resize_to_fit(400, 400)
Pura::Image.save(result, "output.png")
```

## License

MIT

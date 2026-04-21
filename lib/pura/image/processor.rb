# frozen_string_literal: true

module Pura
  module Image
    class Processor
      MAGIC_BYTES = {
        jpeg: [0xFF, 0xD8],
        png: [0x89, 0x50, 0x4E, 0x47],
        gif: [0x47, 0x49, 0x46],           # "GIF"
        bmp: [0x42, 0x4D],                 # "BM"
        tiff_le: [0x49, 0x49, 0x2A, 0x00], # "II*\0" little-endian
        tiff_be: [0x4D, 0x4D, 0x00, 0x2A], # "MM\0*" big-endian
        webp: [0x52, 0x49, 0x46, 0x46],    # "RIFF" (+ "WEBP" at offset 8)
        ico: [0x00, 0x00, 0x01, 0x00],     # ICO
        cur: [0x00, 0x00, 0x02, 0x00]      # CUR
      }.freeze

      EXTENSION_MAP = {
        ".jpg" => :jpeg, ".jpeg" => :jpeg,
        ".png" => :png,
        ".bmp" => :bmp,
        ".gif" => :gif,
        ".tif" => :tiff, ".tiff" => :tiff,
        ".webp" => :webp,
        ".ico" => :ico,
        ".cur" => :ico
      }.freeze

      class << self
        def detect_format(data)
          bytes = data.bytes

          return :jpeg if bytes[0] == 0xFF && bytes[1] == 0xD8
          return :png if bytes[0..3] == MAGIC_BYTES[:png]
          return :gif if bytes[0..2] == MAGIC_BYTES[:gif]
          return :bmp if bytes[0..1] == MAGIC_BYTES[:bmp]
          return :tiff if bytes[0..3] == MAGIC_BYTES[:tiff_le] || bytes[0..3] == MAGIC_BYTES[:tiff_be]
          return :ico if bytes[0..3] == MAGIC_BYTES[:ico] || bytes[0..3] == MAGIC_BYTES[:cur]

          if bytes[0..3] == MAGIC_BYTES[:webp] && bytes.length >= 12 && (bytes[8..11] == [0x57, 0x45, 0x42, 0x50])
            return :webp # "WEBP"
          end

          raise ArgumentError, "Unsupported image format"
        end

        def detect_format_by_extension(path)
          ext = File.extname(path).downcase
          EXTENSION_MAP[ext] || raise(ArgumentError, "Unsupported file extension: #{ext}")
        end

        def load(path)
          data = File.binread(path, 16)
          format = detect_format(data)
          image = decode_with_format(path, format)
          wrap(image)
        end

        def save(image, path, **options)
          format = detect_format_by_extension(path)
          raw_image = unwrap(image)
          encode_with_format(raw_image, path, format, **options)
        end

        def convert(input_path, output_path, **options)
          image = load(input_path)
          save(image, output_path, **options)
        end

        def wrap(raw_image)
          Wrapper.new(raw_image.width, raw_image.height, raw_image.pixels.dup)
        end

        def unwrap(wrapper)
          Pura::Jpeg::Image.new(wrapper.width, wrapper.height, wrapper.pixels)
        end

        private

        def decode_with_format(path, format)
          case format
          when :jpeg then Pura::Jpeg.decode(path)
          when :png  then Pura::Png.decode(path)
          when :bmp  then Pura::Bmp.decode(path)
          when :gif  then Pura::Gif.decode(path)
          when :tiff then Pura::Tiff.decode(path)
          when :ico  then Pura::Ico.decode(path)
          when :webp
            raise NotImplementedError,
                  "WebP decoding is temporarily disabled while pura-webp's VP8 decoder is rewritten. " \
                  "Track progress at https://github.com/komagata/pura-webp"
          else
            raise ArgumentError, "Unsupported format: #{format}"
          end
        end

        def encode_with_format(image, path, format, **options)
          case format
          when :jpeg
            Pura::Jpeg.encode(image, path, quality: options.fetch(:quality, 85))
          when :png
            png_img = Pura::Png::Image.new(image.width, image.height, image.pixels)
            Pura::Png.encode(png_img, path, compression: options.fetch(:compression, 6))
          when :bmp
            bmp_img = Pura::Bmp::Image.new(image.width, image.height, image.pixels)
            Pura::Bmp.encode(bmp_img, path)
          when :gif
            gif_img = Pura::Gif::Image.new(image.width, image.height, image.pixels)
            Pura::Gif.encode(gif_img, path)
          when :tiff
            tiff_img = Pura::Tiff::Image.new(image.width, image.height, image.pixels)
            Pura::Tiff.encode(tiff_img, path)
          when :ico
            ico_img = Pura::Ico::Image.new(image.width, image.height, image.pixels)
            Pura::Ico.encode(ico_img, path)
          when :webp
            raise NotImplementedError,
                  "WebP encoding is temporarily disabled while pura-webp's VP8 decoder is rewritten. " \
                  "Track progress at https://github.com/komagata/pura-webp"
          else
            raise ArgumentError, "Unsupported output format: #{format}"
          end
        end
      end
    end

    class Wrapper
      include Operations

      attr_reader :width, :height, :pixels

      def initialize(width, height, pixels)
        @width = width
        @height = height
        @pixels = pixels.dup
        @pixels.force_encoding(Encoding::BINARY)
      end

      def pixel_at(x, y)
        raise IndexError, "Coordinates out of bounds" if x.negative? || x >= @width || y.negative? || y >= @height

        offset = ((y * @width) + x) * 3
        [@pixels.getbyte(offset), @pixels.getbyte(offset + 1), @pixels.getbyte(offset + 2)]
      end

      def to_rgb_array
        result = []
        i = 0
        size = @pixels.bytesize
        while i < size
          result << [@pixels.getbyte(i), @pixels.getbyte(i + 1), @pixels.getbyte(i + 2)]
          i += 3
        end
        result
      end

      def to_ppm
        "P6\n#{@width} #{@height}\n255\n" + @pixels
      end

      def resize(new_width, new_height)
        raw = Pura::Jpeg::Image.new(@width, @height, @pixels)
        resized = raw.resize(new_width, new_height)
        self.class.new(resized.width, resized.height, resized.pixels)
      end

      def resize_fit(max_width, max_height)
        raw = Pura::Jpeg::Image.new(@width, @height, @pixels)
        fitted = raw.resize_fit(max_width, max_height)
        self.class.new(fitted.width, fitted.height, fitted.pixels)
      end

      def resize_fill(fill_width, fill_height)
        raw = Pura::Jpeg::Image.new(@width, @height, @pixels)
        filled = raw.resize_fill(fill_width, fill_height)
        self.class.new(filled.width, filled.height, filled.pixels)
      end

      def crop(x, y, w, h)
        raw = Pura::Jpeg::Image.new(@width, @height, @pixels)
        cropped = raw.crop(x, y, w, h)
        self.class.new(cropped.width, cropped.height, cropped.pixels)
      end
    end
  end
end

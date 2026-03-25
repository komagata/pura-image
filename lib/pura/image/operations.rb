# frozen_string_literal: true

module Pura
  module Image
    module Operations
      def rotate(degrees)
        case degrees % 360
        when 0
          dup_image
        when 90
          rotate90
        when 180
          rotate180
        when 270
          rotate270
        else
          raise ArgumentError, "Only 90, 180, 270 degree rotations are supported"
        end
      end

      def grayscale
        new_pixels = String.new(encoding: Encoding::BINARY, capacity: @pixels.bytesize)
        i = 0
        size = @pixels.bytesize
        while i < size
          r = @pixels.getbyte(i)
          g = @pixels.getbyte(i + 1)
          b = @pixels.getbyte(i + 2)
          gray = ((r + g + b) / 3.0).round
          new_pixels << gray << gray << gray
          i += 3
        end
        self.class.new(@width, @height, new_pixels)
      end

      def resize_to_limit(max_width, max_height)
        return dup_image if @width <= max_width && @height <= max_height

        scale = [@width.to_f / max_width, @height.to_f / max_height].max
        new_w = [(@width / scale).round, 1].max
        new_h = [(@height / scale).round, 1].max
        resize(new_w, new_h)
      end

      def resize_to_fit(max_width, max_height)
        scale = [@width.to_f / max_width, @height.to_f / max_height].max
        new_w = [(@width / scale).round, 1].max
        new_h = [(@height / scale).round, 1].max
        resize(new_w, new_h)
      end

      def resize_to_fill(fill_width, fill_height)
        resize_fill(fill_width, fill_height)
      end

      def resize_and_pad(target_width, target_height, background: [0, 0, 0])
        # First resize_to_fit
        scale = [@width.to_f / target_width, @height.to_f / target_height].max
        new_w = [(@width / scale).round, 1].max
        new_h = [(@height / scale).round, 1].max
        resized = resize(new_w, new_h)

        # Create padded canvas
        r, g, b = background
        bg_row = (String.new(encoding: Encoding::BINARY) << r << g << b) * target_width
        canvas = bg_row * target_height

        # Center the resized image on the canvas
        offset_x = (target_width - resized.width) / 2
        offset_y = (target_height - resized.height) / 2

        resized.height.times do |y|
          src_start = y * resized.width * 3
          dst_start = (((offset_y + y) * target_width) + offset_x) * 3
          canvas[dst_start, resized.width * 3] = resized.pixels[src_start, resized.width * 3]
        end

        self.class.new(target_width, target_height, canvas)
      end

      def resize_to_cover(cover_width, cover_height)
        scale = [@width.to_f / cover_width, @height.to_f / cover_height].min
        new_w = [(@width / scale).round, 1].max
        new_h = [(@height / scale).round, 1].max
        resize(new_w, new_h)
      end

      def strip
        dup_image
      end

      private

      def dup_image
        self.class.new(@width, @height, @pixels.dup)
      end

      def rotate90
        new_w = @height
        new_h = @width
        new_pixels = String.new(encoding: Encoding::BINARY, capacity: new_w * new_h * 3)

        new_h.times do |y|
          new_w.times do |x|
            # (x, y) in new image comes from (y, height-1-x) in old image
            src_offset = (((@height - 1 - x) * @width) + y) * 3
            new_pixels << @pixels[src_offset, 3]
          end
        end
        self.class.new(new_w, new_h, new_pixels)
      end

      def rotate180
        new_pixels = String.new(encoding: Encoding::BINARY, capacity: @pixels.bytesize)
        (@height - 1).downto(0) do |y|
          (@width - 1).downto(0) do |x|
            offset = ((y * @width) + x) * 3
            new_pixels << @pixels[offset, 3]
          end
        end
        self.class.new(@width, @height, new_pixels)
      end

      def rotate270
        new_w = @height
        new_h = @width
        new_pixels = String.new(encoding: Encoding::BINARY, capacity: new_w * new_h * 3)

        new_h.times do |y|
          new_w.times do |x|
            # (x, y) in new image comes from (width-1-y, x) in old image
            src_offset = ((x * @width) + (@width - 1 - y)) * 3
            new_pixels << @pixels[src_offset, 3]
          end
        end
        self.class.new(new_w, new_h, new_pixels)
      end
    end
  end
end

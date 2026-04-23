# frozen_string_literal: true

require "pura/processing"

require_relative "../pura-image"

module ImageProcessing
  module Pura
    extend ::Pura::Processing::Chainable

    def self.valid_image?(file)
      path = file.respond_to?(:path) ? file.path : file.to_s
      data = File.binread(path, 8)
      format = ::Pura::Image::Processor.detect_format(data)
      return false unless format

      ::Pura::Image::Processor.load(path)
      true
    rescue StandardError
      false
    end

    class Processor < ::Pura::Processing::Processor
      accumulator :image, ::Pura::Image::Wrapper

      def self.supports_resize_on_load?
        false
      end

      def self.load_image(path_or_image, **_options)
        if path_or_image.is_a?(::Pura::Image::Wrapper)
          path_or_image
        elsif path_or_image.is_a?(String)
          ::Pura::Image::Processor.load(path_or_image)
        elsif path_or_image.respond_to?(:path)
          ::Pura::Image::Processor.load(path_or_image.path)
        else
          raise ::Pura::Processing::Error, "unsupported source: #{path_or_image.inspect}"
        end
      end

      def self.save_image(wrapper, destination, **options)
        ::Pura::Image::Processor.save(wrapper, destination.to_s, **options)
      end

      def resize_to_limit(width, height, **_options)
        w = image.width
        h = image.height

        return image if w <= (width || w) && h <= (height || h)

        width ||= w
        height ||= h
        image.resize_to_fit(width, height)
      end

      def resize_to_fit(width, height, **_options)
        width ||= image.width
        height ||= image.height
        image.resize_to_fit(width, height)
      end

      def resize_to_fill(width, height, **_options)
        image.resize_to_fill(width, height)
      end

      def resize_and_pad(width, height, background: nil, **_options)
        bg = background || [0, 0, 0]
        image.resize_and_pad(width, height, background: bg)
      end

      def resize_to_cover(width, height, **_options)
        image.resize_to_cover(width, height)
      end

      def crop(left, top, width, height, **_options)
        image.crop(left, top, width, height)
      end

      def rotate(degrees, **_options)
        image.rotate(degrees)
      end

      def colourspace(space, **_options)
        if %w[b-w grey16].include?(space.to_s)
          image.grayscale
        else
          image
        end
      end

      def strip(**_options)
        image.strip
      end

      def convert(format, **_options)
        # Store desired format for save_image
        @format = format.to_s.delete(".")
        image
      end
    end
  end
end

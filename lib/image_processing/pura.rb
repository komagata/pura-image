# frozen_string_literal: true

require "pura/processing"

require_relative "../pura-image"

module ImageProcessing
  module Pura
    extend ::Pura::Processing::Chainable

    def self.valid_image?(file)
      path = file.respond_to?(:path) ? file.path : file.to_s
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

      def self.load_image(path_or_image, page: 0)
        raise ArgumentError, "only the first image (page: 0) is supported" unless page.is_a?(Integer) && page.zero?

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

      def resize_to_limit(width, height)
        image.resize_to_limit(width, height)
      end

      def resize_to_fit(width, height)
        image.resize_to_fit(width, height)
      end

      def resize_to_fill(width, height)
        image.resize_to_fill(width, height)
      end

      def resize_and_pad(width, height, background: nil)
        bg = background || [0, 0, 0]
        image.resize_and_pad(width, height, background: bg)
      end

      def resize_to_cover(width, height)
        image.resize_to_cover(width, height)
      end

      def crop(left, top, width, height)
        image.crop(left, top, width, height)
      end

      def rotate(degrees)
        image.rotate(degrees)
      end

      def colourspace(space)
        if %w[b-w grey16].include?(space.to_s)
          image.grayscale
        else
          image
        end
      end

      def strip
        image.strip
      end

      def convert(format)
        # Store desired format for save_image
        @format = format.to_s.delete(".")
        image
      end
    end
  end
end

# frozen_string_literal: true

require "pura-jpeg"
require "pura-png"
require "pura-bmp"
require "pura-gif"
require "pura-tiff"
require "pura-ico"
begin
  require "pura-webp"
rescue LoadError
  # pura-webp is optional — install the gem to enable WebP support.
end

require_relative "pura/image/version"
require_relative "pura/image/operations"
require_relative "pura/image/processor"
require_relative "pura/image/railtie" if defined?(Rails::Railtie)

module Pura
  module Image
    class << self
      def load(path)
        Processor.load(path)
      end

      def save(image, path, **options)
        Processor.save(image, path, **options)
      end

      def convert(input_path, output_path, **options)
        Processor.convert(input_path, output_path, **options)
      end

      def detect_format(data)
        Processor.detect_format(data)
      end

      def supported_formats
        formats = %i[jpeg png bmp gif tiff ico]
        formats << :webp if defined?(Pura::Webp)
        formats
      end
    end
  end
end

# frozen_string_literal: true

require "image_processing/pura"
require "active_storage/transformers/transformer"

module Pura
  module Image
    # Uses Active Storage's backend-independent lifecycle without image_processing.
    class Transformer < ActiveStorage::Transformers::Transformer
      SUPPORTED_OPERATIONS = %i[
        resize_to_limit resize_to_fit resize_to_fill resize_and_pad resize_to_cover
        crop rotate grayscale colourspace strip
      ].freeze

      private

      def process(file, format:)
        operations = transformations.each_with_object([]) do |(name, argument), result|
          raise ArgumentError, "unsupported transformation: #{name}" unless SUPPORTED_OPERATIONS.include?(name.to_sym)

          result << [name, argument] if argument.present?
        end

        ImageProcessing::Pura.source(file).convert(format).apply(operations).call
      end
    end
  end
end

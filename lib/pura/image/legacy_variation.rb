# frozen_string_literal: true

module Pura
  module Image
    # Rails versions before variant_transformer= select the backend in Variation.
    module LegacyVariation
      private

      def transformer
        return super unless ActiveStorage.variant_processor == :pura

        Pura::Image::Transformer.new(transformations.except(:format))
      end
    end
  end
end

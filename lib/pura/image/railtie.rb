# frozen_string_literal: true

require "rails/railtie"

module Pura
  module Image
    class Railtie < Rails::Railtie
      initializer "pura_image.configure_active_storage" do
        ActiveSupport.on_load(:active_storage_blob) do
          require "image_processing/pura"

          # Override Variation#transformer to use Pura
          ActiveStorage::Variation.class_eval do
            private

            def transformer
              @pura_transformer ||= begin
                klass = Class.new(ActiveStorage::Transformers::ImageProcessingTransformer) do
                  private
                  def processor
                    ImageProcessing::Pura
                  end
                end
                klass.new(transformations.except(:format))
              end
            end
          end
        end
      end
    end
  end
end

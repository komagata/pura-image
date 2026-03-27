# frozen_string_literal: true

# Only define railtie if Rails is available
if defined?(Rails)
  require "rails/railtie"

  module Pura
    module Image
      class Railtie < Rails::Railtie
        initializer "pura_image.set_variant_processor", before: "active_storage.configs" do |app|
          app.config.active_storage.variant_processor = :pura
        end

        initializer "pura_image.patch_active_storage_variation" do
          ActiveSupport.on_load(:active_storage_blob) do
            require "image_processing/pura"

            variation_patch = Module.new do
              private

              def transformer
                if ActiveStorage.variant_processor == :pura && ActiveStorage.variant_transformer.nil?
                  @pura_transformer ||= begin
                    klass = Class.new(ActiveStorage::Transformers::ImageProcessingTransformer) do
                      private

                      def processor
                        ImageProcessing::Pura
                      end
                    end

                    klass.new(transformations.except(:format))
                  end
                else
                  super
                end
              end
            end

            unless ActiveStorage::Variation.ancestors.include?(variation_patch)
              ActiveStorage::Variation.prepend(variation_patch)
            end
          end
        end
      end
    end
  end
end

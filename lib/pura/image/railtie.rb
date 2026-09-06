# frozen_string_literal: true

require "rails/railtie"

module Pura
  module Image
    class Railtie < Rails::Railtie
      initializer "pura_image.configure_active_storage", after: "active_storage.configs" do |app|
        app.config.after_initialize do
          if defined?(ActiveStorage) && ActiveStorage.variant_processor == :pura
            require_relative "transformer"
            if ActiveStorage.respond_to?(:variant_transformer=)
              ActiveStorage.variant_transformer = Pura::Image::Transformer
            else
              require_relative "legacy_variation"
              ActiveSupport.on_load(:active_storage_blob) do
                unless ActiveStorage::Variation < Pura::Image::LegacyVariation
                  ActiveStorage::Variation.prepend(Pura::Image::LegacyVariation)
                end
              end
            end
          end
        end
      end
    end
  end
end

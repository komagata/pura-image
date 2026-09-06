# frozen_string_literal: true

require "rails/railtie"

module Pura
  module Image
    class Railtie < Rails::Railtie
      initializer "pura_image.configure_active_storage", after: "active_storage.configs" do |app|
        app.config.after_initialize do
          if defined?(ActiveStorage) && ActiveStorage.variant_processor == :pura
            require_relative "transformer"
            ActiveStorage.variant_transformer = Pura::Image::Transformer
          end
        end
      end
    end
  end
end

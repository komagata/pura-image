# frozen_string_literal: true

# Run in a fresh process: ruby -Ilib test/integration/active_storage.rb pura
require "tmpdir"
require "logger"
require "rails"
require "active_record/railtie"
require "active_storage/engine"
require "pura-image"

processor = ARGV.fetch(0, "pura").to_sym
ENV["RAILS_ENV"] = "test"
ENV["DATABASE_URL"] = "sqlite3::memory:"

Dir.mktmpdir("pura-rails") do |root|
  application = Class.new(Rails::Application) do
    config.root = root
    config.global_id.app = "pura-test"
    config.eager_load = ENV["EAGER_LOAD"] == "1"
    config.secret_key_base = "test-secret-key-base"
    config.logger = Logger.new(File::NULL)
    config.active_storage.service = :test
    config.active_storage.service_configurations = { test: { service: "Disk", root: "#{root}/storage" } }
    config.active_storage.variant_processor = processor
    config.active_storage.track_variants = false
    config.active_job.queue_adapter = :inline
  end
  application.initialize!

  raise "processor setting was overwritten" unless ActiveStorage.variant_processor == processor
  raise "image_processing was loaded" if Gem.loaded_specs.key?("image_processing")
  raise "ruby-vips was loaded" if Gem.loaded_specs.key?("ruby-vips")
  raise "mini_magick was loaded" if Gem.loaded_specs.key?("mini_magick")

  if processor == :pura
    ActiveRecord::Schema.define do
      create_table :active_storage_blobs do |t|
        t.string :key, null: false
        t.string :filename, null: false
        t.string :content_type
        t.text :metadata
        t.string :service_name, null: false
        t.bigint :byte_size, null: false
        t.string :checksum
        t.datetime :created_at, null: false
      end
    end

    File.open(File.join(__dir__, "../fixtures/test_64x64.jpg"), "rb") do |file|
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: "photo.jpg", content_type: "image/jpeg")
      variant = blob.variant(resize_to_limit: [16, 16], format: :png).processed
      image = Pura::Png.decode(variant.download)
      raise "incorrect variant dimensions" unless [image.width, image.height] == [16, 16]

      begin
        blob.variant(system: "unsupported").processed
        raise "unsupported transformation was accepted"
      rescue ArgumentError => e
        raise unless e.message.include?("unsupported transformation")
      end
    end
  end
end
puts "PASS: Active Storage processor=#{processor}, eager_load=#{ENV.fetch("EAGER_LOAD", "0")}"

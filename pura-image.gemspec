# frozen_string_literal: true

require_relative "lib/pura/image/version"

Gem::Specification.new do |spec|
  spec.name = "pura-image"
  spec.version = Pura::Image::VERSION
  spec.authors = ["komagata"]
  spec.email = ["komagata@gmail.com"]

  spec.summary = "Pure Ruby image processing library"
  spec.description = "Unified image processing library bundling all pura-* format gems " \
                     "with image_processing gem compatible API for Rails Active Storage."
  spec.homepage = "https://github.com/komagata/pura-image"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["lib/**/*.rb"] + ["test/fixtures/test_64x64.jpg"] + ["pura-image.gemspec", "Gemfile", "Rakefile", "README.md", "LICENSE"]

  spec.add_dependency "pura-jpeg", "~> 0.1"
  spec.add_dependency "pura-png", "~> 0.1"
  spec.add_dependency "pura-bmp", "~> 0.1"
  spec.add_dependency "pura-gif", "~> 0.1"
  spec.add_dependency "pura-tiff", "~> 0.1"
  spec.add_dependency "pura-ico", "~> 0.1"
  spec.add_dependency "pura-webp", "~> 0.2"
  spec.add_dependency "pura-processing", "~> 0.1"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end

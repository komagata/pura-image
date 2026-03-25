require_relative "lib/pure/image/version"

Gem::Specification.new do |spec|
  spec.name = "pura-image"
  spec.version = Pura::Image::VERSION
  spec.authors = ["komagata"]
  spec.email = ["komagata@gmail.com"]

  spec.summary = "Pure Ruby image processing library"
  spec.description = "Unified image processing library bundling pura-jpeg and pura-png with image_processing gem compatible API"
  spec.homepage = "https://github.com/komagata/pura-image"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["lib/**/*.rb"] + ["pura-image.gemspec", "Gemfile", "Rakefile", "README.md", "LICENSE"]

  spec.add_dependency "pura-jpeg", "~> 0.1"
  spec.add_dependency "pura-png", "~> 0.1"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end

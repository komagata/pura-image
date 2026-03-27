# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.join(__dir__, "..", "lib"))
require "pura-image"

class TestMinimal < Minitest::Test
  def test_version_defined
    assert defined?(Pura::Image::VERSION)
    assert Pura::Image::VERSION.is_a?(String)
    assert_match(/\d+\.\d+\.\d+/, Pura::Image::VERSION)
  end

  def test_module_structure
    assert defined?(Pura::Image)
    assert Pura::Image.respond_to?(:supported_formats)
    assert Pura::Image.supported_formats.is_a?(Array)
    assert Pura::Image.supported_formats.include?(:jpeg)
  end
end

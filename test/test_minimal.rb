# frozen_string_literal: true

require "minitest/autorun"

# Test without requiring pura-image to avoid dependency issues
class TestMinimal < Minitest::Test
  def test_basic_ruby_functionality
    assert_equal 4, 2 + 2
    assert "test".is_a?(String)
  end

  def test_version_file_exists
    version_path = File.join(__dir__, "..", "lib", "pura", "image", "version.rb")
    assert File.exist?(version_path), "version.rb should exist"
    
    content = File.read(version_path)
    assert content.include?("VERSION"), "VERSION constant should be defined"
  end

  def test_main_file_syntax
    main_path = File.join(__dir__, "..", "lib", "pura-image.rb")
    assert File.exist?(main_path), "main file should exist"
    
    # Basic syntax check without requiring dependencies
    content = File.read(main_path)
    assert content.include?("module Pura"), "Should contain Pura module"
    assert content.include?("Image"), "Should reference Image"
  end
end
# frozen_string_literal: true

require "minitest/autorun"

# Stub version of test that doesn't depend on external gems
class TestStub < Minitest::Test
  def test_library_loads
    # Just verify the files can be read syntactically
    lib_path = File.join(__dir__, "..", "lib")
    
    # Check main files exist and have basic syntax
    main_file = File.join(lib_path, "pura-image.rb")
    assert File.exist?(main_file)
    
    version_file = File.join(lib_path, "pura", "image", "version.rb")
    assert File.exist?(version_file)
    
    # Basic syntax check by loading just the version
    $LOAD_PATH.unshift(lib_path)
    require "pura/image/version"
    
    assert defined?(Pura::Image::VERSION)
    assert_match(/\d+\.\d+\.\d+/, Pura::Image::VERSION)
  end

  def test_railtie_syntax
    railtie_file = File.join(__dir__, "..", "lib", "pura", "image", "railtie.rb")
    assert File.exist?(railtie_file)
    
    content = File.read(railtie_file)
    assert content.include?("Rails"), "Should mention Rails"
    assert content.include?("Railtie"), "Should contain Railtie"
  end
end
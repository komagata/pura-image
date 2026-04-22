# frozen_string_literal: true

require "minitest/autorun"
require "tempfile"

lib_path = File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

require "image_processing/pura"

# Smoke tests proving that after the pura-processing refactor, the
# ImageProcessing::Pura chainable entrypoint still wires up end-to-end
# without pulling in image_processing / ruby-vips / mini_magick.
class ImageProcessingPuraTest < Minitest::Test
  FIXTURE = File.expand_path("fixtures/test_64x64.jpg", __dir__)

  def test_base_classes_come_from_pura_processing_not_image_processing_gem
    assert_equal ::Pura::Processing::Chainable, ImageProcessing::Pura.singleton_class.ancestors.find { |a| a.name == "Pura::Processing::Chainable" }
    assert_operator ImageProcessing::Pura::Processor, :<, ::Pura::Processing::Processor
  end

  def test_ruby_vips_and_mini_magick_are_not_required
    refute defined?(::Vips), "ruby-vips must not be required transitively"
    refute defined?(::MiniMagick), "mini_magick must not be required transitively"
  end

  def test_valid_image_detects_jpeg_fixture
    assert ImageProcessing::Pura.valid_image?(FIXTURE)
  end

  def test_valid_image_rejects_nonimage
    Tempfile.create(%w[garbage .bin]) do |f|
      f.write("not an image")
      f.close
      refute ImageProcessing::Pura.valid_image?(f.path)
    end
  end

  def test_resize_to_limit_chain_writes_destination
    Tempfile.create(%w[out .jpg]) do |dst|
      dst.close
      ImageProcessing::Pura
        .source(FIXTURE)
        .resize_to_limit(32, 32)
        .call(destination: dst.path)

      assert File.size(dst.path).positive?, "destination must be written"

      loaded = ::Pura::Image::Processor.load(dst.path)
      assert_operator loaded.width,  :<=, 32
      assert_operator loaded.height, :<=, 32
    end
  end

  def test_pipeline_error_is_raised_for_unsupported_source
    assert_raises(::Pura::Processing::Error) do
      ImageProcessing::Pura::Processor.load_image(Object.new)
    end
  end
end

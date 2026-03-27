# frozen_string_literal: true

require "minitest/autorun"
require "pura-image"
require "tmpdir"

class TestOperations < Minitest::Test
  def setup
    # Use fixture from this repo instead of external path
    fixture_path = File.join(__dir__, "fixtures", "test_64x64.jpg")
    @image = Pura::Image.load(fixture_path)
  end

  # 4. Rotate 90/180/270
  def test_rotate_90
    result = @image.rotate(90)
    assert_equal @image.height, result.width
    assert_equal @image.width, result.height
    assert_equal result.width * result.height * 3, result.pixels.bytesize
  end

  def test_rotate_180
    result = @image.rotate(180)
    assert_equal @image.width, result.width
    assert_equal @image.height, result.height
    assert_equal result.width * result.height * 3, result.pixels.bytesize
  end

  def test_rotate_270
    result = @image.rotate(270)
    assert_equal @image.height, result.width
    assert_equal @image.width, result.height
    assert_equal result.width * result.height * 3, result.pixels.bytesize
  end

  # 5. Resize operations
  def test_resize
    result = @image.resize(32, 32)
    assert_equal 32, result.width
    assert_equal 32, result.height
    assert_equal 32 * 32 * 3, result.pixels.bytesize
  end

  def test_resize_to_limit
    result = @image.resize_to_limit(100, 100)
    assert_equal @image.width, result.width
    assert_equal @image.height, result.height
  end

  def test_resize_to_limit_smaller
    result = @image.resize_to_limit(32, 32)
    assert_equal 32, result.width
    assert_equal 32, result.height
  end

  def test_resize_to_fit
    result = @image.resize_to_fit(100, 50)
    assert result.width <= 100
    assert result.height <= 50
  end

  def test_resize_to_fill
    result = @image.resize_to_fill(80, 40)
    assert_equal 80, result.width
    assert_equal 40, result.height
  end

  def test_resize_and_pad
    result = @image.resize_and_pad(100, 100)
    assert_equal 100, result.width
    assert_equal 100, result.height
  end

  def test_resize_and_pad_custom_background
    result = @image.resize_and_pad(100, 100, background: [255, 0, 0])
    assert_equal 100, result.width
    assert_equal 100, result.height
  end

  def test_resize_to_cover
    result = @image.resize_to_cover(80, 40)
    assert result.width >= 80
    assert result.height >= 40
  end

  # 6. Crop - basic functionality
  def test_crop
    result = @image.crop(10, 10, 20, 20)
    assert_equal 20, result.width
    assert_equal 20, result.height
    assert_equal 20 * 20 * 3, result.pixels.bytesize
  end

  # Basic smoke tests for core functionality
  def test_image_loaded
    assert_equal 64, @image.width
    assert_equal 64, @image.height
    assert @image.pixels.is_a?(String)
  end
end
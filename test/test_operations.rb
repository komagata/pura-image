# frozen_string_literal: true

require "minitest/autorun"
require "pura-image"
require "tmpdir"

class TestOperations < Minitest::Test
  JPEG_FIXTURE = "/tmp/pura-jpeg/test/fixtures/test_64x64.jpg"

  def setup
    @image = Pura::Image.load(JPEG_FIXTURE)
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
  end

  def test_rotate_270
    result = @image.rotate(270)
    assert_equal @image.height, result.width
    assert_equal @image.width, result.height
  end

  def test_rotate_0
    result = @image.rotate(0)
    assert_equal @image.width, result.width
    assert_equal @image.height, result.height
    assert_equal @image.pixels, result.pixels
  end

  def test_rotate_360
    result = @image.rotate(360)
    assert_equal @image.width, result.width
    assert_equal @image.pixels, result.pixels
  end

  def test_rotate_invalid
    assert_raises(ArgumentError) { @image.rotate(45) }
  end

  # Verify rotate 90 pixel mapping
  def test_rotate_90_pixel_correctness
    # Create a small test image: 2x3, so rotated 90 should be 3x2
    pixels = String.new(encoding: Encoding::BINARY)
    # Row 0: (0,0)=R, (1,0)=G
    # Row 1: (0,1)=B, (1,1)=W
    # Row 2: (0,2)=K, (1,2)=Y
    pixels << [255, 0, 0].pack("C3")   # (0,0) Red
    pixels << [0, 255, 0].pack("C3")   # (1,0) Green
    pixels << [0, 0, 255].pack("C3")   # (0,1) Blue
    pixels << [255, 255, 255].pack("C3") # (1,1) White
    pixels << [0, 0, 0].pack("C3")     # (0,2) Black
    pixels << [255, 255, 0].pack("C3") # (1,2) Yellow

    img = Pura::Image::Wrapper.new(2, 3, pixels)
    rotated = img.rotate(90)

    assert_equal 3, rotated.width
    assert_equal 2, rotated.height

    # After 90 CW rotation of a 2x3 image to 3x2:
    # New (x,y) comes from old (y, height-1-x)
    # Row 0 of rotated (y=0): x=0 from old(0,2)=K, x=1 from old(1,2)=Y... wait
    # Let me think: new(x,y) = old(y, old_h-1-x)
    # new(0,0) = old(0, 2) = Black
    # new(1,0) = old(1, 2) = Yellow
    # new(2,0) = old(2, 2) -- out of bounds for old width=2
    # Hmm, for new image 3x2:
    # new_h = old_w = 2, new_w = old_h = 3
    # new(x,y) where x in 0..2, y in 0..1
    # src = old(old_h-1-x, y) ... no, let me re-derive
    # 90 CW: new(x,y) = old(y, old_height-1-x)
    # new(0,0) = old(0, 3-1-0) = old(0,2) = Black
    assert_equal [0, 0, 0], rotated.pixel_at(0, 0)
    # new(1,0) = old(0, 3-1-1) = old(0,1) = Blue
    assert_equal [0, 0, 255], rotated.pixel_at(1, 0)
    # new(2,0) = old(0, 3-1-2) = old(0,0) = Red
    assert_equal [255, 0, 0], rotated.pixel_at(2, 0)
    # new(0,1) = old(1, 2) = Yellow
    assert_equal [255, 255, 0], rotated.pixel_at(0, 1)
    # new(1,1) = old(1, 1) = White
    assert_equal [255, 255, 255], rotated.pixel_at(1, 1)
    # new(2,1) = old(1, 0) = Green
    assert_equal [0, 255, 0], rotated.pixel_at(2, 1)
  end

  # 5. Grayscale
  def test_grayscale
    result = @image.grayscale
    assert_equal @image.width, result.width
    assert_equal @image.height, result.height

    # Each pixel should have r == g == b
    pixel = result.pixel_at(0, 0)
    assert_equal pixel[0], pixel[1]
    assert_equal pixel[1], pixel[2]
  end

  def test_grayscale_values
    # Create a known image: one red pixel
    pixels = [255, 0, 0].pack("C3")
    img = Pura::Image::Wrapper.new(1, 1, pixels)
    gray = img.grayscale
    # (255+0+0)/3 = 85
    assert_equal [85, 85, 85], gray.pixel_at(0, 0)
  end

  # 7. resize_and_pad
  def test_resize_and_pad_dimensions
    result = @image.resize_and_pad(100, 80)
    assert_equal 100, result.width
    assert_equal 80, result.height
  end

  def test_resize_and_pad_default_background
    result = @image.resize_and_pad(100, 80)
    # Default background is black
    corner = result.pixel_at(0, 0)
    assert_equal [0, 0, 0], corner
  end

  def test_resize_and_pad_custom_background
    result = @image.resize_and_pad(100, 80, background: [0, 255, 0])
    # Corner should be green
    corner = result.pixel_at(0, 0)
    assert_equal [0, 255, 0], corner
  end

  # Strip (no-op)
  def test_strip
    result = @image.strip
    assert_equal @image.width, result.width
    assert_equal @image.height, result.height
    assert_equal @image.pixels, result.pixels
  end

  # resize_to_limit preserves aspect ratio
  def test_resize_to_limit_aspect_ratio
    result = @image.resize_to_limit(32, 16)
    assert result.width <= 32
    assert result.height <= 16
    # Since original is 64x64 (square), fitting into 32x16 should give 16x16
    assert_equal result.width, result.height
  end

  # resize_to_fit
  def test_resize_to_fit_non_square
    result = @image.resize_to_fit(32, 16)
    assert result.width <= 32
    assert result.height <= 16
  end

  # resize_to_cover
  def test_resize_to_cover_covers_bounds
    result = @image.resize_to_cover(30, 20)
    assert result.width >= 30
    assert result.height >= 20
  end

  # Chaining operations
  def test_chaining_operations
    result = @image.resize_to_fit(32, 32).rotate(90).grayscale
    assert_equal 32, result.width
    assert_equal 32, result.height
    pixel = result.pixel_at(0, 0)
    assert_equal pixel[0], pixel[1]
  end
end

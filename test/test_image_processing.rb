# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift(File.join(__dir__, "..", "lib"))
$LOAD_PATH.unshift("/tmp/pura-jpeg/lib")
$LOAD_PATH.unshift("/tmp/pura-png/lib")

require "image_processing/pura"

class TestImageProcessingPure < Minitest::Test
  def setup
    # Create a 100x80 test JPEG
    pixels = String.new(encoding: Encoding::BINARY)
    80.times do |y|
      100.times do |x|
        pixels << (x * 255 / 100).chr << (y * 255 / 80).chr << 128.chr
      end
    end
    @jpeg_path = "/tmp/ip_test_src.jpg"
    img = Pura::Jpeg::Image.new(100, 80, pixels)
    Pura::Jpeg.encode(img, @jpeg_path, quality: 90)

    # Create a test PNG
    @png_path = "/tmp/ip_test_src.png"
    png_img = Pura::Png::Image.new(100, 80, pixels)
    Pura::Png.encode(png_img, @png_path)
  end

  def test_resize_to_limit
    dest = "/tmp/ip_test_limit.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .resize_to_limit(50, 50)
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert_equal 50, result.width
    assert result.height <= 50
  end

  def test_resize_to_limit_no_upscale
    dest = "/tmp/ip_test_limit_noup.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .resize_to_limit(200, 200)
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert_equal 100, result.width
    assert_equal 80, result.height
  end

  def test_resize_to_fit
    dest = "/tmp/ip_test_fit.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .resize_to_fit(50, 50)
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert result.width <= 50
    assert result.height <= 50
  end

  def test_resize_to_fill
    dest = "/tmp/ip_test_fill.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .resize_to_fill(60, 60)
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert_equal 60, result.width
    assert_equal 60, result.height
  end

  def test_resize_and_pad
    dest = "/tmp/ip_test_pad.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .resize_and_pad(120, 120)
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert_equal 120, result.width
    assert_equal 120, result.height
  end

  def test_resize_to_cover
    dest = "/tmp/ip_test_cover.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .resize_to_cover(60, 60)
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert result.width >= 60
    assert result.height >= 60
  end

  def test_crop
    dest = "/tmp/ip_test_crop.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .crop(10, 10, 50, 40)
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert_equal 50, result.width
    assert_equal 40, result.height
  end

  def test_rotate_90
    dest = "/tmp/ip_test_rot90.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .rotate(90)
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert_equal 80, result.width
    assert_equal 100, result.height
  end

  def test_rotate_180
    dest = "/tmp/ip_test_rot180.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .rotate(180)
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert_equal 100, result.width
    assert_equal 80, result.height
  end

  def test_colourspace_bw
    dest = "/tmp/ip_test_bw.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .colourspace("b-w")
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert_equal 100, result.width
    # Verify grayscale: R == G == B for each pixel
    r, g, b = result.pixel_at(50, 40)
    assert_equal r, g
    assert_equal g, b
  end

  def test_strip
    dest = "/tmp/ip_test_strip.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .strip
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert_equal 100, result.width
  end

  def test_convert_jpeg_to_png
    dest = "/tmp/ip_test_convert.png"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .resize_to_limit(50, 50)
      .call(destination: dest)

    result = Pura::Png.decode(dest)
    assert_equal 50, result.width
    assert result.height <= 50
  end

  def test_convert_png_to_jpeg
    dest = "/tmp/ip_test_png2jpg.jpg"
    ImageProcessing::Pura
      .source(@png_path)
      .resize_to_limit(50, 50)
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert_equal 50, result.width
  end

  def test_pipeline_branching
    pipeline = ImageProcessing::Pura.source(@jpeg_path)

    pipeline.resize_to_limit(80, 80).call(destination: "/tmp/ip_branch_l.jpg")
    pipeline.resize_to_limit(30, 30).call(destination: "/tmp/ip_branch_s.jpg")

    rl = Pura::Jpeg.decode("/tmp/ip_branch_l.jpg")
    rs = Pura::Jpeg.decode("/tmp/ip_branch_s.jpg")

    assert_equal 80, rl.width
    assert_equal 30, rs.width
  end

  def test_chained_operations
    dest = "/tmp/ip_test_chain.jpg"
    ImageProcessing::Pura
      .source(@jpeg_path)
      .resize_to_limit(50, 50)
      .rotate(90)
      .colourspace("b-w")
      .call(destination: dest)

    result = Pura::Jpeg.decode(dest)
    assert result.width <= 50
  end

  def test_valid_image_jpeg
    assert ImageProcessing::Pura.valid_image?(@jpeg_path)
  end

  def test_valid_image_png
    assert ImageProcessing::Pura.valid_image?(@png_path)
  end

  def test_valid_image_invalid
    File.write("/tmp/ip_test_invalid.txt", "not an image")
    refute ImageProcessing::Pura.valid_image?("/tmp/ip_test_invalid.txt")
  end
end

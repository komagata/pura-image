# frozen_string_literal: true

require "minitest/autorun"
require "pura-image"
require "tmpdir"

class TestProcessor < Minitest::Test
  JPEG_FIXTURE = "/tmp/pura-jpeg/test/fixtures/test_64x64.jpg"
  PNG_FIXTURE = "/tmp/pura-png/test/fixtures/rgb_8bit.png"

  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  # 1. Load JPEG and PNG
  def test_load_jpeg
    image = Pura::Image.load(JPEG_FIXTURE)
    assert_instance_of Pura::Image::Wrapper, image
    assert_equal 64, image.width
    assert_equal 64, image.height
    assert_equal 64 * 64 * 3, image.pixels.bytesize
  end

  def test_load_png
    image = Pura::Image.load(PNG_FIXTURE)
    assert_instance_of Pura::Image::Wrapper, image
    assert image.width.positive?
    assert image.height.positive?
    assert_equal image.width * image.height * 3, image.pixels.bytesize
  end

  # 2. All resize operations with dimension checks
  def test_resize_to_limit_downscales
    image = Pura::Image.load(JPEG_FIXTURE)
    result = image.resize_to_limit(32, 32)
    assert result.width <= 32
    assert result.height <= 32
  end

  def test_resize_to_limit_no_upscale
    image = Pura::Image.load(JPEG_FIXTURE)
    result = image.resize_to_limit(128, 128)
    assert_equal 64, result.width
    assert_equal 64, result.height
  end

  def test_resize_to_fit
    image = Pura::Image.load(JPEG_FIXTURE)
    result = image.resize_to_fit(32, 16)
    assert result.width <= 32
    assert result.height <= 16
  end

  def test_resize_to_fill
    image = Pura::Image.load(JPEG_FIXTURE)
    result = image.resize_to_fill(40, 30)
    assert_equal 40, result.width
    assert_equal 30, result.height
  end

  def test_resize_and_pad
    image = Pura::Image.load(JPEG_FIXTURE)
    result = image.resize_and_pad(100, 80, background: [255, 0, 0])
    assert_equal 100, result.width
    assert_equal 80, result.height
    # Check corner pixel is background color (red)
    corner = result.pixel_at(0, 0)
    assert_equal [255, 0, 0], corner
  end

  def test_resize_to_cover
    image = Pura::Image.load(JPEG_FIXTURE)
    result = image.resize_to_cover(30, 20)
    assert result.width >= 30
    assert result.height >= 20
  end

  # 3. Format conversion JPEG to PNG and back
  def test_convert_jpeg_to_png
    output = File.join(@tmpdir, "converted.png")
    Pura::Image.convert(JPEG_FIXTURE, output)
    assert File.exist?(output)
    # Verify it's a valid PNG
    data = File.binread(output)
    assert_equal :png, Pura::Image.detect_format(data)
  end

  def test_convert_png_to_jpeg
    output = File.join(@tmpdir, "converted.jpg")
    Pura::Image.convert(PNG_FIXTURE, output)
    assert File.exist?(output)
    data = File.binread(output)
    assert_equal :jpeg, Pura::Image.detect_format(data)
  end

  # 6. Crop
  def test_crop
    image = Pura::Image.load(JPEG_FIXTURE)
    result = image.crop(10, 10, 20, 20)
    assert_equal 20, result.width
    assert_equal 20, result.height
  end

  # 8. Pipeline: load -> resize -> convert -> save
  def test_pipeline
    image = Pura::Image.load(JPEG_FIXTURE)
    resized = image.resize_to_fit(32, 32)
    output = File.join(@tmpdir, "pipeline.png")
    Pura::Image.save(resized, output)
    assert File.exist?(output)

    reloaded = Pura::Image.load(output)
    assert reloaded.width <= 32
    assert reloaded.height <= 32
  end

  # 9. Format detection from magic bytes
  def test_detect_jpeg_format
    data = File.binread(JPEG_FIXTURE)
    assert_equal :jpeg, Pura::Image.detect_format(data)
  end

  def test_detect_png_format
    data = File.binread(PNG_FIXTURE)
    assert_equal :png, Pura::Image.detect_format(data)
  end

  # 10. Error handling for unsupported formats
  def test_unsupported_format_detection
    assert_raises(ArgumentError) { Pura::Image.detect_format("XXXX_NOT_AN_IMAGE") }
  end

  def test_unsupported_file_extension
    image = Pura::Image.load(JPEG_FIXTURE)
    assert_raises(ArgumentError) { Pura::Image.save(image, "output.xyz") }
  end

  # 11. New format support
  def test_detect_gif_format
    assert_equal :gif, Pura::Image.detect_format("GIF89a\x00\x00")
  end

  def test_detect_bmp_format
    assert_equal :bmp, Pura::Image.detect_format("BM\x00\x00\x00\x00\x00\x00")
  end

  # Save with options
  def test_save_jpeg_with_quality
    image = Pura::Image.load(JPEG_FIXTURE)
    output = File.join(@tmpdir, "quality.jpg")
    Pura::Image.save(image, output, quality: 50)
    assert File.exist?(output)
  end

  def test_save_png_with_compression
    image = Pura::Image.load(JPEG_FIXTURE)
    output = File.join(@tmpdir, "compressed.png")
    Pura::Image.save(image, output, compression: 9)
    assert File.exist?(output)
  end

  # pixel_at and to_rgb_array
  def test_pixel_at
    image = Pura::Image.load(JPEG_FIXTURE)
    pixel = image.pixel_at(0, 0)
    assert_equal 3, pixel.length
    pixel.each { |c| assert_includes 0..255, c }
  end

  def test_to_rgb_array
    image = Pura::Image.load(JPEG_FIXTURE)
    arr = image.to_rgb_array
    assert_equal 64 * 64, arr.length
    assert_equal 3, arr[0].length
  end
end

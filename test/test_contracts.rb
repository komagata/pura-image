# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "image_processing/pura"

class TestContracts < Minitest::Test
  def setup
    @image = Pura::Image::Wrapper.new(2, 2, "\xFF\x00\x00".b * 4)
  end

  def test_valid_image_accepts_decodable_webp
    path = File.join(__dir__, "fixtures", "test_16x16.webp")
    assert_equal 16, Pura::Image.load(path).width
    assert ImageProcessing::Pura.valid_image?(path)
  end

  def test_cur_output_is_rejected_without_creating_a_disguised_ico
    Dir.mktmpdir do |dir|
      path = File.join(dir, "out.cur")
      assert_raises(ArgumentError) { Pura::Image.save(@image, path) }
      refute_path_exists path
    end
  end

  def test_fit_with_one_unbounded_dimension_can_upscale
    [[4, nil], [nil, 4]].each do |size|
      result = ImageProcessing::Pura.source(@image).resize_to_fit(*size).call(save: false)
      assert_equal [4, 4], [result.width, result.height]
    end
  end

  def test_direct_resize_accepts_one_unbounded_dimension
    fitted = @image.resize_to_fit(nil, 4)
    limited = @image.resize_to_limit(1, nil)
    assert_equal [4, 4], [fitted.width, fitted.height]
    assert_equal [1, 1], [limited.width, limited.height]
  end

  def test_resize_rejects_invalid_dimensions
    [[nil, nil], [0, 1], [-1, 2], [1.5, 2]].each do |size|
      assert_raises(ArgumentError) { @image.resize_to_fit(*size) }
      assert_raises(ArgumentError) { @image.resize_to_limit(*size) }
    end
  end

  def test_unsupported_operation_options_are_not_silently_ignored
    assert_raises(ArgumentError) do
      ImageProcessing::Pura.source(@image).resize_to_fill(1, 2, gravity: "northwest").call(save: false)
    end
  end

  def test_unsupported_saver_options_are_not_silently_ignored
    Dir.mktmpdir do |dir|
      assert_raises(ArgumentError) { Pura::Image.save(@image, File.join(dir, "out.png"), quality: 50) }
    end
  end

  def test_unsupported_loader_options_are_not_silently_ignored
    assert_raises(ArgumentError) do
      ImageProcessing::Pura.source(@image).loader(page: 1).call(save: false)
    end
  end
end

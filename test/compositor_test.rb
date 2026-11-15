require_relative "test_helper"

class CompositorTest < Minitest::Test
  RED = 0xFFFF0000

  def red_frame(width, height)
    frame = IO::Buffer.new(width * height * 4)
    (0...width * height).each { |index| frame.set_value(:u32, index * 4, RED) }
    frame
  end

  def pixel(compositor, x, y)
    compositor.out.get_value(:u32, (y * 640 + x) * 4)
  end

  def setup
    @compositor = Compositor.new(320, 200, 320, 200, 640, 400, background, SETTINGS.render.halve_below)
    @compositor.draw(red_frame(320, 200), 0.0, 0.0, 320.0, 200.0)
  end

  def test_the_recording_fills_the_window
    assert_equal RED, pixel(@compositor, 320, 200)
  end

  def test_the_margin_shows_the_wallpaper
    refute_equal RED, pixel(@compositor, 5, 5)
  end

  def test_a_crop_reaching_past_the_frame_edge_stays_inside_it
    @compositor.draw(red_frame(320, 200), 0.0, 0.0, 330.0, 205.0)
    assert_equal RED, pixel(@compositor, 320, 200)
  end

  def test_a_small_view_of_a_large_frame_averages_its_pixels
    compositor = Compositor.new(1280, 800, 1280, 800, 640, 400, background, SETTINGS.render.halve_below)
    frame = IO::Buffer.new(1280 * 800 * 4)
    (0...1280 * 800).each { |index| frame.set_value(:u32, index * 4, (index / 1280 + index).even? ? 0xFFFFFFFF : 0xFF000000) }
    compositor.draw(frame, 0.0, 0.0, 1280.0, 800.0)
    middle = compositor.out.get_value(:u32, (200 * 640 + 320) * 4)
    assert_includes 0x70..0x90, middle & 0xFF, "a fine checkerboard should come out grey"
  end

  def test_the_window_corners_are_rounded
    refute_equal RED, pixel(@compositor, @compositor.window_left, @compositor.window_top)
    assert_equal RED, pixel(@compositor, @compositor.window_left + 30, @compositor.window_top + 30)
  end
end

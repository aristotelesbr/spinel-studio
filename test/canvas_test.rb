require_relative "test_helper"

class CanvasTest < Minitest::Test
  WHITE = 0xFFFFFFFF

  def pixel(canvas, x, y)
    canvas.pixels.get_value(:u32, (y * canvas.width + x) * 4)
  end

  def test_a_rounded_rectangle_fills_its_middle_and_leaves_its_corners
    canvas = Canvas.new(40, 40)
    canvas.clear(0)
    canvas.fill_rounded(0, 0, 40, 40, 12, WHITE)
    assert_equal WHITE, pixel(canvas, 20, 20)
    assert_equal 0, pixel(canvas, 0, 0)
  end

  def test_the_edge_of_a_circle_is_antialiased
    canvas = Canvas.new(40, 40)
    canvas.clear(0)
    canvas.circle(20, 20, 10.5, WHITE)
    edge_alpha = pixel(canvas, 30, 20) >> 24
    assert edge_alpha > 0 && edge_alpha < 255
  end

  def test_mix_takes_the_weighted_share_of_each_pixel
    assert_equal 0xFF000000, Pixel.mix(0xFF000000, 0xFFFFFFFF, 0)
    assert_equal 0xFFFFFFFF, Pixel.mix(0xFF000000, 0xFFFFFFFF, 256)
    assert_includes 127..128, (Pixel.mix(0xFF000000, 0xFFFFFFFF, 128) >> 8) & 0xFF
  end

  def test_average_of_four_pixels
    assert_equal 0xFF808080, Pixel.average(0xFFFFFFFF, 0xFFFFFFFF, 0xFF000000, 0xFF020202)
  end

  def test_blit_copies_only_the_shown_columns
    canvas = Canvas.new(10, 4)
    canvas.clear(0)
    image = IO::Buffer.new(4 * 2 * 4)
    (0...8).each { |index| image.set_value(:u32, index * 4, 0xFFFFFFFF) }
    canvas.blit(image, 4, 2, 2, 1, 3, 5)
    shown = (0...10).map { |x| canvas.pixels.get_value(:u32, (1 * 10 + x) * 4) != 0 }
    assert_equal [false, false, false, true, true, false, false, false, false, false], shown
  end

  def test_an_opaque_color_covers_what_is_under_it
    assert_equal 0xFF336699, Pixel.over(0xFF000000, 0xFF336699, 255)
  end

  def test_a_line_covers_the_pixels_along_it
    canvas = Canvas.new(20, 20)
    canvas.clear(0)
    canvas.line(2, 10, 18, 10, 2, WHITE)
    assert_equal 0xFF, pixel(canvas, 10, 10) >> 24
    assert_equal 0, pixel(canvas, 10, 2)
  end
end

class CursorSpriteTest < Minitest::Test
  def color(sprite, x, y)
    sprite.pixels.get_value(:u32, (y * CursorSprite::SIZE + x) * 4)
  end

  def test_the_arrow_is_black_inside_and_white_on_its_edge
    sprite = CursorSprite.new(cursor_style)
    inside = color(sprite, 24, 60)
    assert_equal 0xFF, inside >> 24
    assert_equal 0, inside & 0xFFFFFF
    edge = color(sprite, 10, 60)
    assert_equal 0xFF, edge & 0xFF
  end

  def test_far_from_the_arrow_the_sprite_is_clear
    assert_equal 0, color(CursorSprite.new(cursor_style), 150, 10)
  end
end

class TriangleTest < Minitest::Test
  def test_a_triangle_fills_inside_and_not_outside
    canvas = Canvas.new(40, 40)
    canvas.clear(0)
    canvas.fill_triangle([[10, 5], [35, 20], [10, 35]], 0xFFFFFFFF)
    inside = canvas.pixels.get_value(:u32, (20 * 40 + 18) * 4)
    outside = canvas.pixels.get_value(:u32, (5 * 40 + 35) * 4)
    assert_equal 0xFF, inside >> 24
    assert_equal 0, outside
  end
end

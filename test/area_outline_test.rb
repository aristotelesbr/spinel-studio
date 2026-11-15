require_relative "test_helper"

class AreaOutlineTest < Minitest::Test
  def setup
    @canvas = AreaOutline.new(100, 60, 1.0, SETTINGS.recording).paint
  end

  def alpha(x, y)
    @canvas.pixels.get_value(:u32, (y * @canvas.width + x) * 4) >> 24
  end

  def test_the_frame_reaches_past_the_area_on_every_side
    assert_equal 100 + 2 * AreaOutline::BORDER, @canvas.width
    assert_equal 60 + 2 * AreaOutline::BORDER, @canvas.height
  end

  def test_the_area_itself_stays_clear
    inside = AreaOutline::BORDER + 30
    assert_equal 0, alpha(inside, inside)
  end

  def test_the_line_runs_along_the_edges
    line = AreaOutline::BORDER - AreaOutline::GAP - 1
    assert_equal 0xFF, alpha(60, line)
    assert_equal 0xFF, alpha(line, 40)
  end
end

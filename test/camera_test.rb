require_relative "test_helper"

class CameraTest < Minitest::Test
  AREA = [0, 0, 2000, 1000].freeze

  def setup
    @track = track_of([[0.0, 1500, 500, false], [2.0, 1500, 500, true], [2.1, 1500, 500, false], [9.0, 1500, 500, false]])
    @plan = zoom_plan(ZoomPlan.segments_for_clicks(@track.clicks, zoom_style))
  end

  def test_outside_a_zoom_it_shows_the_whole_area
    camera = Camera.new(@plan, @track, AREA, 30, camera_style)
    camera.update(0.5, 1500, 500)
    assert_equal [0.0, 0.0, 2000.0, 1000.0], camera.crop
  end

  def test_zooming_in_centers_on_the_click
    camera = Camera.new(@plan, @track, AREA, 30, camera_style)
    camera.update(2.0, 1500, 500)
    x, y, width, height = camera.crop
    assert_in_delta 1000.0, width
    assert_in_delta 1500.0, x + width / 2
    assert_in_delta 500.0, y + height / 2
  end

  def test_the_view_stays_inside_the_area
    track = track_of([[0.0, 1990, 990, false], [1.0, 1990, 990, true], [5.0, 1990, 990, false]])
    camera = Camera.new(zoom_plan(ZoomPlan.segments_for_clicks(track.clicks, zoom_style)), track, AREA, 30, camera_style)
    camera.update(1.0, 1990, 990)
    x, y, width, height = camera.crop
    assert x + width <= 2000.0
    assert y + height <= 1000.0
  end

  def test_small_moves_in_the_middle_do_not_pan
    camera = Camera.new(@plan, @track, AREA, 30, camera_style)
    camera.update(2.0, 1500, 500)
    before = camera.crop
    10.times { |frame| camera.update(2.0 + frame / 30.0, 1560, 520) }
    assert_equal before, camera.crop
  end

  def test_the_view_follows_a_cursor_near_the_edge
    camera = Camera.new(@plan, @track, AREA, 30, camera_style)
    camera.update(2.0, 1500, 500)
    before = camera.crop
    30.times { |frame| camera.update(2.0 + frame / 30.0, 1060, 500) }
    assert camera.crop[0] < before[0]
  end
end

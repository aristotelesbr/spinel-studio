require_relative "test_helper"

class CursorTest < Minitest::Test
  FPS = 30

  def shaky_track
    shake = Random.new(7)
    samples = (0..600).map do |step|
      time = step / 120.0
      [time, 500 + time * 300 + shake.rand(-15.0..15.0), 400, (time - 3.0).abs < 0.001]
    end
    track_of(samples)
  end

  def path(track, frames)
    cursor = Cursor.new(track, FPS, cursor_style, SETTINGS.render.cursor_steps_per_frame)
    frames.map do |frame|
      cursor.update(frame.to_f / FPS)
      [cursor.x, cursor.scale]
    end
  end

  def wobble(values)
    steps = values.each_cons(3).map { |a, b, c| (a - 2 * b + c).abs }
    steps.sum / steps.size
  end

  def test_the_cursor_glides_instead_of_shaking
    track = shaky_track
    raw = (0...120).map { |frame| track.x_at(frame.to_f / FPS) }
    smooth = path(track, 0...120).map(&:first)
    assert wobble(smooth) < wobble(raw) / 5
  end

  def test_the_cursor_is_close_to_the_click_when_it_happens
    track = shaky_track
    x = path(track, 0..90).last[0]
    assert_in_delta track.x_at(3.0), x, 25
  end

  def test_the_cursor_dips_right_after_a_click
    scales = path(shaky_track, 0..100).map(&:last)
    assert scales[92] < 1.0
    assert_in_delta 1.0, scales[50]
  end
end

require_relative "test_helper"

class TrackTest < Minitest::Test
  def test_the_position_between_two_samples_is_interpolated
    track = track_of([[0.0, 0, 100, false], [1.0, 200, 300, false]])
    assert_in_delta 50.0, track.x_at(0.25)
    assert_in_delta 150.0, track.y_at(0.25)
  end

  def test_before_the_first_and_after_the_last_sample_the_position_holds
    track = track_of([[1.0, 10, 20, false], [2.0, 30, 40, false]])
    assert_in_delta 10.0, track.x_at(0.0)
    assert_in_delta 30.0, track.x_at(5.0)
  end

  def test_a_click_is_the_moment_the_button_goes_down
    track = track_of([[0.0, 0, 0, false], [0.1, 0, 0, true], [0.2, 0, 0, true], [0.3, 0, 0, false], [0.4, 0, 0, true]])
    assert_equal [0.1, 0.4], track.clicks
  end

  def test_the_end_line_is_not_a_sample
    track = Track.new(["0.0 5 5 0", "end 3.0"])
    assert_in_delta 5.0, track.x_at(10.0)
  end

  def test_time_since_the_latest_click
    track = track_of([[0.0, 0, 0, false], [1.0, 0, 0, true], [1.1, 0, 0, false]])
    assert_in_delta 0.5, track.since_click(1.5)
    assert_equal Float::INFINITY, track.since_click(0.5)
  end
end

require_relative "test_helper"

class TimelineTest < Minitest::Test
  def setup
    @timeline = Timeline.new([Span.new(0.0, 10.0)], [])
  end

  def test_a_fresh_timeline_keeps_the_whole_recording
    fresh = Timeline.fresh(12.0, [3.0], zoom_style)
    assert_equal [[0.0, 12.0]], fresh.clips.map { |clip| [clip.start, clip.finish] }
    assert_equal 1, fresh.zooms.size
  end

  def test_split_makes_two_clips_that_meet_at_the_time
    right = @timeline.split(4.0, 0.3)
    assert_equal [[0.0, 4.0], [4.0, 10.0]], @timeline.clips.map { |clip| [clip.start, clip.finish] }
    assert_same right, @timeline.clips[1]
  end

  def test_split_too_near_an_edge_does_nothing
    assert_nil @timeline.split(0.1, 0.3)
    assert_equal 1, @timeline.clips.size
  end

  def test_removing_a_clip_leaves_a_gap_that_is_not_kept
    @timeline.split(4.0, 0.3)
    @timeline.split(6.0, 0.3)
    @timeline.remove(@timeline.clip_at(5.0))
    refute @timeline.kept?(5.0)
    assert @timeline.kept?(3.0)
    assert_in_delta 8.0, @timeline.length
  end

  def test_playback_resumes_after_a_gap
    @timeline.split(4.0, 0.3)
    @timeline.split(6.0, 0.3)
    @timeline.remove(@timeline.clip_at(5.0))
    assert_in_delta 3.0, @timeline.resume_at(3.0)
    assert_in_delta 6.0, @timeline.resume_at(5.0)
    @timeline.remove(@timeline.clip_at(7.0))
    assert_nil @timeline.resume_at(7.0)
  end

  def test_fit_trims_to_the_recording
    timeline = Timeline.new([Span.new(0.0, 12.0)], [Span.new(9.0, 13.0, 2.0), Span.new(11.0, 12.0, 2.0)])
    timeline.fit(10.6)
    assert_in_delta 10.6, timeline.clips[0].finish
    assert_equal [[9.0, 10.6]], timeline.zooms.map { |zoom| [zoom.start, zoom.finish] }
  end
end

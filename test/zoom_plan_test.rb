require_relative "test_helper"

class ZoomPlanTest < Minitest::Test
  def plan_for(clicks)
    zoom_plan(ZoomPlan.segments_for_clicks(clicks, zoom_style))
  end

  def test_clicks_close_together_make_one_segment
    segments = ZoomPlan.segments_for_clicks([2.0, 3.0, 5.5], zoom_style)
    assert_equal 1, segments.size
    assert_in_delta 2.0 - zoom_style.lead, segments[0].start
    assert_in_delta 5.5 + zoom_style.hold, segments[0].finish
  end

  def test_clicks_far_apart_make_separate_segments
    assert_equal 2, ZoomPlan.segments_for_clicks([1.0, 10.0], zoom_style).size
  end

  def test_a_segment_never_starts_before_the_video
    assert_in_delta 0.0, ZoomPlan.segments_for_clicks([0.2], zoom_style)[0].start
  end

  def test_the_zoom_is_fully_in_at_the_click
    plan = plan_for([4.0])
    assert_in_delta 2.0, plan.scale_at(4.0)
    assert_in_delta 1.0, plan.scale_at(1.0)
    assert_in_delta 1.0, plan.scale_at(4.0 + zoom_style.hold + 0.01)
  end

  def test_the_zoom_eases_in_without_jumps_or_reversals
    plan = plan_for([4.0])
    scales = (0..50).map { |step| plan.scale_at(4.0 - zoom_style.lead + step * 0.01) }
    assert scales.each_cons(2).all? { |before, after| after >= before }, "the zoom went back while easing in"
    assert scales.each_cons(2).all? { |before, after| after - before < 0.08 }, "the zoom jumped"
  end

  def test_a_short_segment_ramps_over_half_its_length
    assert_in_delta 1.0, Span.new(0.0, 0.4, 2.0).strength_at(0.2, 0.5)
  end

  def test_ease_is_flat_at_both_ends
    assert_in_delta 0.0, Span.ease(0.0)
    assert_in_delta 1.0, Span.ease(1.0)
    assert_in_delta 0.5, Span.ease(0.5)
    assert Span.ease(0.05) < 0.05
  end
end

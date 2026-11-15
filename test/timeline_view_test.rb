require_relative "test_helper"

class TimelineViewTest < Minitest::Test
  def setup
    @timeline = Timeline.new([Span.new(0.0, 20.0)], [Span.new(2.0, 4.0, 2.0), Span.new(8.0, 10.0, 2.0)])
    @view = TimelineView.new(@timeline, 20.0, SETTINGS.editor)
  end

  def clip_y
    TimelineView::CLIP_TOP + 10
  end

  def zoom_y
    TimelineView::ZOOM_TOP + 10
  end

  def far_away
    19.0
  end

  def test_times_and_positions_map_both_ways
    assert_in_delta 7.5, @view.time_at(@view.x_at(7.5))
    assert_in_delta 0.0, @view.time_at(0)
    assert_in_delta 20.0, @view.time_at(5000)
  end

  def test_the_ruler_and_the_playhead_ask_for_a_seek
    assert_equal :seek, @view.press(400, TimelineView::RULER_TOP + 2, far_away)
    assert_equal :seek, @view.press(@view.x_at(3.0) + 4, zoom_y, 3.0)
    assert_equal [2.0, 4.0], [@timeline.zooms[0].start, @timeline.zooms[0].finish]
  end

  def test_split_at_the_playhead_selects_the_right_piece
    @view.split(6.0)
    assert_equal 2, @timeline.clips.size
    assert_same @timeline.clips[1], @view.selected
  end

  def test_dragging_a_clip_edge_trims_it_up_to_its_neighbor
    @view.split(6.0)
    @view.press(@view.x_at(6.0) - 2, clip_y, far_away)
    @view.drag(@view.x_at(9.0))
    @view.release
    assert_in_delta 6.0, @timeline.clips[0].finish, 0.001
    @view.press(@view.x_at(0.0), clip_y, far_away)
    @view.drag(@view.x_at(1.5))
    @view.release
    assert_in_delta 1.5, @timeline.clips[0].start, 0.05
  end

  def test_a_clip_body_only_selects
    @view.press(@view.x_at(10.0), clip_y, far_away)
    @view.drag(@view.x_at(15.0))
    @view.release
    assert_equal [[0.0, 20.0]], @timeline.clips.map { |clip| [clip.start, clip.finish] }
    assert_equal :clip, @view.selected_kind
  end

  def test_deleting_a_piece_leaves_a_gap_but_never_the_last_clip
    @view.press(@view.x_at(10.0), clip_y, far_away)
    @view.release
    @view.delete_selected
    assert_equal 1, @timeline.clips.size
    @view.split(6.0)
    @view.delete_selected
    assert_equal [[0.0, 6.0]], @timeline.clips.map { |clip| [clip.start, clip.finish] }
  end

  def test_dragging_a_zoom_moves_it_and_keeps_its_length
    @view.press(@view.x_at(3.0), zoom_y, far_away)
    @view.drag(@view.x_at(4.0))
    @view.release
    assert_in_delta 3.0, @timeline.zooms[0].start, 0.05
    assert_in_delta 5.0, @timeline.zooms[0].finish, 0.05
  end

  def test_a_zoom_cannot_be_dragged_over_its_neighbor
    @view.press(@view.x_at(3.0), zoom_y, far_away)
    @view.drag(@view.x_at(12.0))
    @view.release
    assert_in_delta 8.0, @timeline.zooms[0].finish, 0.001
  end

  def test_a_click_in_an_empty_zoom_spot_adds_a_default_zoom
    @view.press(@view.x_at(15.0), zoom_y, far_away)
    @view.release
    added = @timeline.zooms.last
    assert_in_delta SETTINGS.editor.new_zoom_length, added.length
    assert_in_delta 2.0, added.amount
  end

  def test_the_zoom_amount_steps_within_limits
    @view.press(@view.x_at(3.0), zoom_y, far_away)
    @view.release
    @view.change_amount(1)
    assert_in_delta 2.25, @timeline.zooms[0].amount
    20.times { @view.change_amount(1) }
    assert_in_delta SETTINGS.editor.largest_zoom, @timeline.zooms[0].amount
  end

  def test_the_pointer_shape_follows_what_is_under_it
    assert_equal :playhead, @view.pointing_at(@view.x_at(12.0), zoom_y, 12.0)
    assert_equal :edge, @view.pointing_at(@view.x_at(4.0), zoom_y, far_away)
    assert_equal :zoom, @view.pointing_at(@view.x_at(3.0), zoom_y, far_away)
    assert_equal :clip, @view.pointing_at(@view.x_at(15.0), clip_y, far_away)
    assert_equal :nothing, @view.pointing_at(@view.x_at(6.0), zoom_y, far_away)
  end
end

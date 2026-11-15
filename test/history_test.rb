require_relative "test_helper"

class HistoryTest < Minitest::Test
  def setup
    @timeline = Timeline.new([Span.new(0.0, 10.0)], [Span.new(2.0, 4.0, 2.0)])
    @history = History.new(@timeline, 100)
  end

  def clips
    @timeline.clips.map { |clip| [clip.start, clip.finish] }
  end

  def edit
    @history.record
    yield
    @history.commit
  end

  def test_undo_brings_back_the_timeline_before_the_edit
    edit { @timeline.split(4.0, 0.3) }
    assert @history.undo
    assert_equal [[0.0, 10.0]], clips
  end

  def test_redo_brings_the_edit_back
    edit { @timeline.split(4.0, 0.3) }
    @history.undo
    assert @history.redo
    assert_equal [[0.0, 4.0], [4.0, 10.0]], clips
  end

  def test_undo_restores_zoom_amounts
    edit { @timeline.zooms[0].amount = 3.0 }
    @history.undo
    assert_in_delta 2.0, @timeline.zooms[0].amount
  end

  def test_a_gesture_that_changed_nothing_leaves_no_step
    edit { nil }
    refute @history.undo
  end

  def test_a_new_edit_clears_redo
    edit { @timeline.split(4.0, 0.3) }
    @history.undo
    edit { @timeline.split(6.0, 0.3) }
    refute @history.redo
  end
end

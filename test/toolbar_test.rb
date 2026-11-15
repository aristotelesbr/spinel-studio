require_relative "test_helper"

class ToolbarTest < Minitest::Test
  def setup
    @typeface = FakeTypeface.new
    @toolbar = Toolbar.new(1.0, @typeface, SETTINGS.theme, SETTINGS.toolbar)
  end

  def point_on(button)
    [Toolbar::MARGIN + Toolbar::BUTTON_LEFT[button] + 20, Toolbar::MARGIN + Toolbar::BUTTON_TOP + 20]
  end

  def test_each_button_answers_where_it_is_drawn
    [:display, :area, :record, :close].each do |button|
      assert_equal button, @toolbar.button_at(*point_on(button))
    end
    assert_equal :none, @toolbar.button_at(Toolbar::MARGIN + Toolbar::TIMER_LEFT + 10, 40)
    assert_equal :none, @toolbar.button_at(2, 2)
  end

  def test_while_recording_only_stop_and_close_respond
    @toolbar.state = :recording
    assert @toolbar.enabled?(:record)
    assert @toolbar.enabled?(:close)
    refute @toolbar.enabled?(:display)
    refute @toolbar.enabled?(:area)
  end

  def test_the_timer_shows_minutes_and_seconds
    @toolbar.state = :recording
    @toolbar.seconds = 83
    @toolbar.paint
    assert_equal ["01:23"], @typeface.drawn
  end

  def test_the_countdown_shows_the_seconds_left
    @toolbar.state = :countdown
    @toolbar.seconds = 2
    @toolbar.paint
    assert_equal ["2"], @typeface.drawn
  end

  def test_hover_fades_in_and_stops_moving
    @toolbar.hover = :area
    assert @toolbar.animate(0.05)
    20.times { @toolbar.animate(0.05) }
    refute @toolbar.animate(0.05)
  end
end

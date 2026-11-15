require_relative "test_helper"

class RecordingSessionTest < Minitest::Test
  def setup
    @session = RecordingSession.new(SETTINGS.recording)
  end

  def test_a_session_starts_idle
    assert_equal :idle, @session.state
    refute @session.recording?
  end

  def test_the_countdown_counts_the_seconds_left
    @session.start_countdown(100.0)
    assert_equal :countdown, @session.state
    assert_equal SETTINGS.recording.countdown, @session.seconds
    @session.tick(101.2, [], [])
    assert_equal SETTINGS.recording.countdown - 1, @session.seconds
    assert_equal :countdown, @session.state
  end

  def test_an_idle_tick_changes_nothing
    @session.tick(100.0, [], [])
    assert_equal :idle, @session.state
    assert_equal 0, @session.seconds
  end
end

# The recording behind the floating bar, from idle through the countdown
# to recording and back to idle with the finished take. The bar shows
# its state and seconds; the app asks it to start and stop.
class RecordingSession
  attr_reader :state, :seconds

  # settings: the recording settings.
  def initialize(settings)
    @settings = settings
    @state = :idle
    @seconds = 0
    @countdown_end = 0.0
    @recorder = nil
  end

  def recording?
    @state == :recording
  end

  def start_countdown(now)
    @state = :countdown
    @countdown_end = now + @settings.countdown
    @seconds = @settings.countdown
  end

  # Moves the countdown on, starting the take when it reaches zero, and
  # samples a running take. area: [] for the whole display, or the
  # picked rectangle; excluded: window numbers to leave out.
  def tick(now, area, excluded)
    if @state == :countdown
      left = (@countdown_end - now).ceil
      if left <= 0
        start(area, excluded)
      else
        @seconds = left
      end
    elsif @state == :recording
      @recorder.sample
      @seconds = @recorder.elapsed.to_i
    end
  end

  # Ends the take; its folder.
  def stop
    @recorder.stop
    @state = :idle
    @seconds = 0
    @recorder.dir
  end

  private

  def start(area, excluded)
    folder = @settings.folder
    Dir.mkdir(folder) unless Dir.exist?(folder)
    dir = "#{folder}/#{Time.now.strftime("%Y-%m-%d %H.%M.%S")}"
    @recorder = Recorder.new(dir, area, excluded, @settings)
    @seconds = 0
    @state = @recorder.start ? :recording : :idle
  end
end

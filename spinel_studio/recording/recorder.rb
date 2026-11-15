# One recording. ScreenCaptureKit keeps the newest frame of the screen
# (minus the toolbar); this program takes one every 1/FPS seconds and
# hands it to the encoder, sampling the cursor into mouse.log in
# between. Frame n is exactly n/FPS seconds after the log's zero.
# What was recorded goes to recording-meta.json.
class Recorder
  FIRST_FRAME_POLL = 0.01   # seconds between looks for the capture's first frame

  attr_reader :dir

  # excluded: window numbers to leave out of the capture. settings: the
  # recording settings (frame rate, encoding, how long to wait for the
  # capture to start).
  def initialize(dir, area, excluded, settings)
    @dir = dir
    @area = area
    @excluded = ExcludedWindows.new(excluded)
    @fps = settings.fps
    @codec = settings.codec
    @bitrate = settings.bitrate
    @first_frame_tries = (settings.capture_start_timeout / FIRST_FRAME_POLL).to_i
    @log = nil
    @pid = 0
    @enc = nil
    @frame = nil
    @frame_size = 0
    @written = 0
    @start = 0.0
    @density = 1
  end

  # Returns false when the capture could not start.
  def start
    Dir.mkdir(@dir) unless Dir.exist?(@dir)
    size = SDL.display_size
    @density = Mouse.pixel_density
    RecordingMeta.new(@fps, @density, @area).save(@dir)
    width = size[0] * @density
    height = size[1] * @density
    status = ScreenCapture.studio_capture_start(@excluded.list, @excluded.count, width, height, @fps)
    if status != 0
      puts "screen capture failed (#{status}); is Screen Recording allowed?"
      return false
    end
    @frame_size = width * height * 3 / 2
    @frame = IO::Buffer.new(@frame_size)
    @first_frame_tries.times do
      break if ScreenCapture.studio_capture_frame(@frame) > 0
      sleep FIRST_FRAME_POLL
    end
    @pid, @enc = FFmpeg.recorder("#{@dir}/screen.mov", width, height, @fps, @codec, @bitrate)
    @log = File.open("#{@dir}/mouse.log", "w")
    @written = 0
    @start = SpinelStudio.now
    true
  end

  def elapsed
    SpinelStudio.now - @start
  end

  # Call often (the app does it every loop, ~120 times a second).
  def sample
    position = Mouse.position(@density)
    @log.puts "#{elapsed.round(4)} #{position[0]} #{position[1]} #{Mouse.pressed? ? 1 : 0}"
    due = (elapsed * @fps).to_i + 1
    return if @written >= due
    ScreenCapture.studio_capture_frame(@frame)
    # if the machine fell behind, repeat the frame to keep the timing
    while @written < due
      FFmpeg.write_frame(@enc, @frame, @frame_size)
      @written += 1
    end
  end

  def stop
    ScreenCapture.studio_capture_stop
    @enc.close
    @log.puts "end #{(@written.to_f / @fps).round(4)}"
    @log.close
    Process.wait(@pid)
  end
end

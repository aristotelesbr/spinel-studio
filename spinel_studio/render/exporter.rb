# Writes the finished video, one recorded frame per step so a window can
# keep drawing its progress in between. Frames outside the timeline's
# clips are read and dropped.
class Exporter
  attr_reader :frames, :path

  # path: where the video goes.
  def initialize(recording, settings, path)
    @recording = recording
    @path = path
    @width = settings.export.width
    @height = settings.export.height
    @composer = FrameComposer.new(recording, settings.render, recording.frame_width, recording.frame_height, @width, @height)
    @frame_size = recording.frame_width * recording.frame_height * 4
    @frame = IO::Buffer.new(@frame_size)
    @decoder_pid, @decoder = FFmpeg.decoder(recording.screen, recording.fps)
    @encoder_pid, @encoder = FFmpeg.encoder(@path, @width, @height, recording.fps, settings.export.codec, settings.export.bitrate)
    @read = 0
    @frames = 0
    @total = (recording.duration * recording.fps).to_i
  end

  # Handles the next recorded frame; false when the recording is over.
  def step
    return false unless FFmpeg.read_frame(@decoder, @frame, @frame_size)
    time = @read.to_f / @recording.fps
    @read += 1
    @composer.compose(@frame, time)
    return true unless @recording.timeline.kept?(time)
    FFmpeg.write_frame(@encoder, @composer.pixels, @width * @height * 4)
    @frames += 1
    true
  end

  # Steps for up to seconds, so a window can draw between slices; false
  # once the recording is over.
  def work(seconds)
    started = SpinelStudio.now
    while SpinelStudio.now - started < seconds
      return false unless step
    end
    true
  end

  def finish
    @encoder.close
    @decoder.close
    Process.wait(@decoder_pid)
    Process.wait(@encoder_pid)
  end

  # Stops the export and removes the unfinished file.
  def cancel
    Process.kill("TERM", @decoder_pid) rescue nil
    Process.kill("TERM", @encoder_pid) rescue nil
    @encoder.close rescue nil
    @decoder.close rescue nil
    Process.wait(@decoder_pid) rescue nil
    Process.wait(@encoder_pid) rescue nil
    File.delete(@path) if File.exist?(@path)
  end

  def progress
    return 0.0 if @total <= 0
    (@read.to_f / @total).clamp(0.0, 1.0)
  end
end

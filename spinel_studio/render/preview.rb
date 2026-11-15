# Frames of the edited video for the editor, made exactly like the
# export, one at a time. Seeking restarts the decoder at the new time.
class Preview
  attr_reader :time

  def initialize(recording, settings)
    @recording = recording
    @composer = FrameComposer.new(recording, settings.render, recording.frame_width, recording.frame_height,
                                  settings.export.width, settings.export.height)
    @frame_size = recording.frame_width * recording.frame_height * 4
    @frame = IO::Buffer.new(@frame_size)
    @decoder_pid = 0
    @decoder = nil
    @time = 0.0
  end

  def pixels
    @composer.pixels
  end

  def seek(time)
    close
    @time = time
    @decoder_pid, @decoder = FFmpeg.preview_decoder(@recording.screen, @recording.fps, time)
    @composer.restart(time)
    advance
  end

  # Composes the frame at the current time and moves one frame on;
  # false at the end of the recording.
  def advance
    return false unless @decoder && FFmpeg.read_frame(@decoder, @frame, @frame_size)
    @composer.compose(@frame, @time)
    @time += 1.0 / @recording.fps
    true
  end

  def close
    FFmpeg.stop(@decoder_pid, @decoder) if @decoder
    @decoder = nil
  end
end

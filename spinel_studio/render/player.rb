# Plays the edited video in the editor, as the player of Cap's editor
# does: frames come from the Preview at the take's frame rate, the gaps
# the cuts left are skipped, and the end stops playback.
class Player
  # settings: the app settings (the export size; how far behind playback
  # may fall before it drops the lost time).
  def initialize(recording, settings)
    @recording = recording
    @catch_up = settings.editor.catch_up
    @preview = Preview.new(recording, settings)
    @playing = false
    @next_frame_at = 0.0
  end

  def playing?
    @playing
  end

  def time
    @preview.time
  end

  def pixels
    @preview.pixels
  end

  def seek(time)
    @preview.seek(time.clamp(0.0, @recording.duration))
  end

  # Plays from the start again when the video had reached its end.
  def toggle(now)
    @playing = !@playing
    @next_frame_at = now
    seek(0.0) if @playing && time >= @recording.duration - 0.05
  end

  def pause
    @playing = false
  end

  # Moves to the next frame when it is due; true when there is a new
  # frame to show.
  def advance(now)
    return false unless @playing && now >= @next_frame_at
    resume = @recording.timeline.resume_at(time)
    return stop if resume.nil?
    @preview.seek(resume) if resume > time
    return stop unless @preview.advance
    @next_frame_at += 1.0 / @recording.fps
    @next_frame_at = now if now - @next_frame_at > @catch_up
    true
  end

  def close
    @preview.close
  end

  private

  def stop
    @playing = false
    false
  end
end

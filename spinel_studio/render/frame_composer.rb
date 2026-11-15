# Makes the frames of the edited video from recorded frames: the camera
# picks the visible part, the compositor puts it on the wallpaper and the
# smoothed cursor goes on top. Export, preview and scrub strip all use it.
#
# The recorded frames may come at a smaller size than the recording
# (source_width x source_height); positions are scaled to match.
class FrameComposer
  # render: the render settings.
  def initialize(recording, render, source_width, source_height, out_width, out_height)
    @recording = recording
    @steps_per_frame = render.cursor_steps_per_frame
    @scale_x = source_width.to_f / recording.frame_width
    @scale_y = source_height.to_f / recording.frame_height
    area = recording.area
    @compositor = Compositor.new(source_width, source_height, (area[2] * @scale_x).to_i, (area[3] * @scale_y).to_i,
                                 out_width, out_height, recording.project.background, render.halve_below)
    @sprite = CursorSprite.new(recording.project.cursor)
    restart(0.0)
  end

  def pixels
    @compositor.out
  end

  # Starts following the cursor and camera from time (after a seek).
  def restart(time)
    project = @recording.project
    plan = ZoomPlan.new(project.timeline.zooms, project.zoom.ramp)
    @cursor = Cursor.new(@recording.track, @recording.fps, project.cursor, @steps_per_frame, time)
    @camera = Camera.new(plan, @recording.track, @recording.area, @recording.fps, project.camera)
  end

  # The next frame in playback order, at time.
  def compose(frame, time)
    @cursor.update(time)
    @camera.update(time, @cursor.x, @cursor.y)
    draw(frame, @cursor.x, @cursor.y, @cursor.scale)
  end

  # A frame on its own (no smoothing from the frames before it).
  def compose_still(frame, time)
    track = @recording.track
    restart(time)
    @camera.update(time, track.x_at(time), track.y_at(time))
    draw(frame, track.x_at(time), track.y_at(time), 1.0)
  end

  private

  def draw(frame, cursor_x, cursor_y, cursor_scale)
    crop = @camera.crop
    x = crop[0] * @scale_x
    y = crop[1] * @scale_y
    width = crop[2] * @scale_x
    height = crop[3] * @scale_y
    @compositor.draw(frame, x, y, width, height)
    @compositor.draw_cursor(@sprite, cursor_x * @scale_x, cursor_y * @scale_y,
                            @recording.project.cursor.size * cursor_scale * @scale_y, x, y, width, height)
  end
end

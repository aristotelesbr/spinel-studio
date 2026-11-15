# The drawn cursor: a spring pulls it toward the recorded position, so
# the shaky path of a hand becomes one smooth glide. Around a click the
# spring tightens, so the arrow is on the button when it is pressed, and
# the arrow dips in size for a moment.
class Cursor
  attr_reader :x, :y, :scale

  # style: a CursorStyle (smoothing, click grip and dip). The spring is
  # stepped steps_per_frame times a frame, so it stays stable.
  def initialize(track, fps, style, steps_per_frame, start = 0.0)
    @track = track
    @smoothing = style.smoothing
    @click_grip = style.click_grip
    @click_before = style.click_before
    @click_after = style.click_after
    @click_dip = style.click_dip
    @click_dip_length = style.click_dip_length
    @steps_per_frame = steps_per_frame
    @step_seconds = 1.0 / fps / steps_per_frame
    @x = track.x_at(start)
    @y = track.y_at(start)
    @speed_x = 0.0
    @speed_y = 0.0
    @scale = 1.0
  end

  def update(time)
    stiffness = near_click?(time) ? @smoothing * @click_grip : @smoothing
    @steps_per_frame.times { spring_step(@track.x_at(time), @track.y_at(time), stiffness) }
    @scale = 1.0 - @click_dip * dip(@track.since_click(time))
  end

  private

  def near_click?(time)
    @track.clicks.any? { |click| click >= time - @click_after && click <= time + @click_before }
  end

  # A critically damped spring: it arrives without overshooting.
  def spring_step(target_x, target_y, stiffness)
    @speed_x += (stiffness * stiffness * (target_x - @x) - 2 * stiffness * @speed_x) * @step_seconds
    @speed_y += (stiffness * stiffness * (target_y - @y) - 2 * stiffness * @speed_y) * @step_seconds
    @x += @speed_x * @step_seconds
    @y += @speed_y * @step_seconds
  end

  def dip(seconds_since_click)
    return 0.0 if seconds_since_click >= @click_dip_length
    Math.sin(seconds_since_click / @click_dip_length * Math::PI)
  end
end

# Which part of the area the video shows. The zoom comes from the plan.
# Entering a segment, the view centers on where the click will be; inside
# it, the view stays put while the cursor moves within its middle and
# glides along only when the cursor nears an edge.
class Camera
  attr_reader :scale

  # area: [x, y, width, height] in frame pixels; style: a CameraStyle.
  def initialize(plan, track, area, fps, style)
    @plan = plan
    @follow = style.follow
    @comfort = style.comfort
    @track = track
    @left = area[0].to_f
    @top = area[1].to_f
    @width = area[2].to_f
    @height = area[3].to_f
    @frame_seconds = 1.0 / fps
    @scale = 1.0
    @center_x = @left + @width / 2
    @center_y = @top + @height / 2
    @speed_x = 0.0
    @speed_y = 0.0
    @segment = nil
  end

  def update(time, cursor_x, cursor_y)
    segment = @plan.segment_at(time)
    aim_at_first_click(segment) if segment && !segment.equal?(@segment)
    @segment = segment
    @scale = @plan.scale_at(time)
    follow(cursor_x, cursor_y) if segment
  end

  # The visible rectangle [x, y, width, height], kept inside the area.
  def crop
    width = @width / @scale
    height = @height / @scale
    x = (@center_x - width / 2).clamp(@left, @left + @width - width)
    y = (@center_y - height / 2).clamp(@top, @top + @height - height)
    [x, y, width, height]
  end

  private

  def aim_at_first_click(segment)
    click = @track.clicks.find { |time| time >= segment.start } || segment.start
    @center_x = @track.x_at(click)
    @center_y = @track.y_at(click)
    @speed_x = 0.0
    @speed_y = 0.0
  end

  def follow(cursor_x, cursor_y)
    view = crop
    target_x = @center_x + overflow(cursor_x, view[0], view[2])
    target_y = @center_y + overflow(cursor_y, view[1], view[3])
    @speed_x += (@follow * @follow * (target_x - @center_x) - 2 * @follow * @speed_x) * @frame_seconds
    @speed_y += (@follow * @follow * (target_y - @center_y) - 2 * @follow * @speed_y) * @frame_seconds
    @center_x += @speed_x * @frame_seconds
    @center_y += @speed_y * @frame_seconds
  end

  # How far position sits past the comfortable middle of a view span.
  def overflow(position, start, length)
    margin = length * (1 - @comfort) / 2
    return position - (start + margin) if position < start + margin
    return position - (start + length - margin) if position > start + length - margin
    0.0
  end
end

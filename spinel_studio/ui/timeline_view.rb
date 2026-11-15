# The editor's timeline as geometry and gestures, with the two tracks of
# Cap's editor: the clip track (the pieces of the recording that stay;
# split at the playhead, trim by dragging an outer edge, select and
# delete) and the zoom track (drag to add, move, resize, delete). Times
# run in recording time, so a removed piece shows as a gap.
#
# Positions are points in the timeline panel.
class TimelineView
  LANE_LEFT = 88
  LANE_RIGHT = 1264
  RULER_TOP = 48
  RULER_HEIGHT = 14
  CLIP_TOP = 66
  ZOOM_TOP = 116
  LANE_HEIGHT = 40

  attr_reader :selected, :selected_kind, :duration

  # settings: the editor settings (shortest clip, new zoom length, zoom
  # step and range, how close the pointer must be to grab an edge or the
  # playhead) and the amount a new zoom starts at.
  def initialize(timeline, duration, settings)
    @timeline = timeline
    @duration = duration
    @default_amount = settings.zoom_amount
    @shortest = settings.shortest_clip
    @new_zoom_length = settings.new_zoom_length
    @zoom_step = settings.zoom_step
    @smallest_zoom = settings.smallest_zoom
    @largest_zoom = settings.largest_zoom
    @edge_grab = settings.edge_grab
    @playhead_grab = settings.playhead_grab
    @selected = nil
    @selected_kind = :none
    @part = :none
    @anchor = 0.0
    @lower = 0.0
    @upper = duration
  end

  def x_at(time)
    LANE_LEFT + time / @duration * (LANE_RIGHT - LANE_LEFT)
  end

  def time_at(x)
    ((x - LANE_LEFT).to_f / (LANE_RIGHT - LANE_LEFT) * @duration).clamp(0.0, @duration)
  end

  def lane_at(y)
    return :clip if y >= CLIP_TOP && y < CLIP_TOP + LANE_HEIGHT
    return :zoom if y >= ZOOM_TOP && y < ZOOM_TOP + LANE_HEIGHT
    :none
  end

  def items(kind)
    kind == :clip ? @timeline.clips : @timeline.zooms
  end

  # What the pointer is over, for the mouse cursor's shape: :playhead
  # (or the ruler), :edge, :clip (a click selects it), :zoom (it can be
  # dragged along) or :nothing.
  def pointing_at(x, y, playhead)
    return :playhead if on_playhead?(x, y, playhead) || on_ruler?(x, y)
    kind = lane_at(y)
    return :nothing if kind == :none
    item = item_at(kind, x)
    return :nothing unless item
    return :edge if edge_at(item, x) != :none
    kind == :zoom ? :zoom : :clip
  end

  # :seek when the press grabs the playhead or the ruler, :edit when it
  # selected, grabbed or started an item, :nothing otherwise.
  def press(x, y, playhead)
    return :seek if on_playhead?(x, y, playhead) || on_ruler?(x, y)
    kind = lane_at(y)
    return :nothing if kind == :none || x < LANE_LEFT
    item = item_at(kind, x)
    if item
      grab(kind, item, x)
    elsif kind == :zoom
      start_new_zoom(time_at(x))
    else
      deselect
      return :nothing
    end
    :edit
  end

  def drag(x)
    return unless @selected && @part != :none
    time = time_at(x)
    case @part
    when :start then @selected.start = time.clamp(@lower, @selected.finish - @shortest)
    when :finish then @selected.finish = time.clamp(@selected.start + @shortest, @upper)
    when :body then move_to(time - @anchor)
    else stretch_new(time)
    end
  end

  def release
    finish_new if @part == :new
    @part = :none
    @timeline.sort
  end

  # Splits the clip under the playhead and selects its right-hand piece.
  def split(time)
    piece = @timeline.split(time, @shortest)
    select(:clip, piece) if piece
  end

  # Removes the selected item; the last clip always stays.
  def delete_selected
    return unless @selected
    return if @selected_kind == :clip && @timeline.clips.size == 1
    @timeline.remove(@selected)
    deselect
  end

  def change_amount(steps)
    return unless @selected_kind == :zoom
    @selected.amount = (@selected.amount + steps * @zoom_step).clamp(@smallest_zoom, @largest_zoom)
  end

  # Nothing selected (also after undo, when the old items are gone).
  def deselect
    @selected = nil
    @selected_kind = :none
  end

  private

  def on_ruler?(x, y)
    y >= RULER_TOP && y < RULER_TOP + RULER_HEIGHT && x >= LANE_LEFT
  end

  def on_playhead?(x, y, playhead)
    y >= RULER_TOP && y < ZOOM_TOP + LANE_HEIGHT && (x - x_at(playhead)).abs <= @playhead_grab
  end

  def item_at(kind, x)
    items(kind).find { |item| x >= x_at(item.start) - @edge_grab && x <= x_at(item.finish) + @edge_grab }
  end

  def edge_at(item, x)
    return :start if (x - x_at(item.start)).abs <= @edge_grab
    return :finish if (x - x_at(item.finish)).abs <= @edge_grab
    :none
  end

  # A clip's edges trim it; its body only selects it. A zoom moves too.
  def grab(kind, item, x)
    select(kind, item)
    edge = edge_at(item, x)
    @part = if edge != :none then edge
            elsif kind == :zoom then :body
            else :none
            end
    @anchor = time_at(x) - item.start
    find_room(kind, item)
  end

  def start_new_zoom(time)
    zoom = Span.new(time, time, @default_amount)
    find_room(:zoom, zoom)
    @timeline.add_zoom(zoom)
    select(:zoom, zoom)
    @part = :new
    @anchor = time
  end

  def select(kind, item)
    @selected = item
    @selected_kind = kind
  end


  # Items of a track may not overlap: one moves between its neighbors.
  def find_room(kind, item)
    @lower = 0.0
    @upper = @duration
    items(kind).each do |other|
      next if other.equal?(item)
      @lower = other.finish if other.finish <= item.start + 1.0e-6 && other.finish > @lower
      @upper = other.start if other.start >= item.finish - 1.0e-6 && other.start < @upper
    end
  end

  def move_to(start)
    length = @selected.length
    @selected.start = start.clamp(@lower, @upper - length)
    @selected.finish = @selected.start + length
  end

  def stretch_new(time)
    reach = time.clamp(@lower, @upper)
    @selected.start = [@anchor, reach].min
    @selected.finish = [@anchor, reach].max
  end

  # A click without a drag gives a zoom of the default length.
  def finish_new
    return if @selected.length >= @shortest
    length = [@new_zoom_length, @upper - @lower].min
    @selected.start = (@anchor - length / 2).clamp(@lower, @upper - length)
    @selected.finish = @selected.start + length
  end
end

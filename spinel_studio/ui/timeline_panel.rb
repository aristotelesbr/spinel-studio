# Paints the editor's lower panel: the header (play, time, the selected
# item's controls, Split, Export), the ruler, and the two tracks with the
# clip track's thumbnails. Positions are points; Editor handles input.
#
# The time readout has a canvas of its own, so playback and scrubbing
# repaint only that (and the playhead, which the renderer draws), not
# the whole panel.
class TimelinePanel
  HEIGHT = 170
  WIDTH = 1280
  HEADER_TOP = 8
  CONTROL_SIZE = 32
  TIME_LEFT = 60
  CLOCK_WIDTH = 230
  INSPECTOR_LEFT = 300
  AMOUNT_LEFT = 392
  AMOUNT_WIDTH = 60

  attr_reader :canvas, :clock, :play, :export

  # theme: the colors and radii; settings: the editor settings (the
  # thumbnails' width, the shortcuts the hint and the keycaps show).
  def initialize(scale, typeface, view, strip, theme, settings)
    @scale = scale
    @typeface = typeface
    @view = view
    @strip = strip
    @theme = theme
    @thumb_width = settings.tile_width
    shortcuts = settings.shortcuts
    @hint = "#{shortcuts.label(:play)} plays  ·  #{shortcuts.label(:split)} splits  ·  " \
            "#{shortcuts.label(:undo)} undoes  ·  drag in the zoom track to add a zoom"
    @canvas = Canvas.new((WIDTH * scale).to_i, (HEIGHT * scale).to_i)
    @clock = Canvas.new((CLOCK_WIDTH * scale).to_i, (CONTROL_SIZE * scale).to_i)
    @play = Button.new(16, HEADER_TOP, CONTROL_SIZE, CONTROL_SIZE, "", :secondary, :play)
    @split = Button.new(1060, HEADER_TOP, 92, CONTROL_SIZE, "Split", :secondary, :split, shortcuts.label(:split))
    @export = Button.new(1160, HEADER_TOP, 104, CONTROL_SIZE, "Export", :primary, :export, shortcuts.label(:export))
    @minus = Button.new(356, HEADER_TOP, CONTROL_SIZE, CONTROL_SIZE, "-", :secondary, :zoom_out)
    @plus = Button.new(456, HEADER_TOP, CONTROL_SIZE, CONTROL_SIZE, "+", :secondary, :zoom_in)
    @delete = Button.new(504, HEADER_TOP, 100, CONTROL_SIZE, "Delete", :danger, :delete, shortcuts.label(:delete))
    @thumb_pixel_width = (@thumb_width * scale).to_i
    @thumb_pixel_height = ((TimelineView::LANE_HEIGHT - 6) * scale).to_i
    slots = ((TimelineView::LANE_RIGHT - TimelineView::LANE_LEFT) / @thumb_width.to_f).ceil
    @thumbs = (0...slots).map { IO::Buffer.new(@thumb_pixel_width * @thumb_pixel_height * 4) }
    @thumb_ready = (0...slots).map { false }
    @strip_frame = IO::Buffer.new(strip.width * strip.height * 4)
  end

  # The buttons the header shows now, for hit testing.
  def buttons
    selected = @view.selected_kind
    shown = [@play, @split, @export]
    shown += [@minus, @plus, @delete] if selected == :zoom
    shown << @delete if selected == :clip
    shown
  end

  def button_at(x, y)
    buttons.find { |button| button.contains?(x, y) }
  end

  # Makes the thumbnails whose strip frames have been written since the
  # last call; true when any is new.
  def refresh_thumbnails
    fresh = false
    @thumbs.each_index do |slot|
      next if @thumb_ready[slot]
      break unless @strip.read(slot_time(slot), @strip_frame)
      shrink_into(@thumbs[slot])
      @thumb_ready[slot] = true
      fresh = true
    end
    fresh
  end

  # hovered and held: the buttons under the pointer and pressed (or nil).
  def paint(playing, status, hovered, held)
    @canvas.clear(@theme.panel)
    paint_header(playing, status, hovered, held)
    paint_ruler
    paint_lane("Video", TimelineView::CLIP_TOP)
    @view.items(:clip).each { |clip| paint_clip(clip) }
    paint_lane("Zoom", TimelineView::ZOOM_TOP)
    @view.items(:zoom).each { |zoom| paint_zoom(zoom) }
  end

  # The time readout, drawn at TIME_LEFT, HEADER_TOP over the panel.
  def paint_clock(playhead)
    @clock.clear(@theme.panel)
    @typeface.draw(@clock, "#{time_text(playhead)} / #{time_text(@view.duration)}", 0, dots(8).to_i, true, @theme.text)
  end

  private

  def dots(points)
    points * @scale
  end

  def label(text, x, y, large, color)
    @typeface.draw(@canvas, text, dots(x).to_i, dots(y).to_i, large, color)
  end

  def paint_header(playing, status, hovered, held)
    buttons.each { |button| button.paint(@canvas, @typeface, @theme, @scale, button.equal?(hovered), button.equal?(held)) }
    play_icon(playing)
    if @view.selected
      paint_inspector
    else
      label(status.empty? ? @hint : status, INSPECTOR_LEFT, HEADER_TOP + 9, false, @theme.dim_text)
    end
  end

  def play_icon(playing)
    left = @play.left
    top = @play.top
    if playing
      @canvas.fill_rounded(dots(left + 11), dots(top + 9), dots(4), dots(14), dots(1), @theme.text)
      @canvas.fill_rounded(dots(left + 18), dots(top + 9), dots(4), dots(14), dots(1), @theme.text)
    else
      @canvas.fill_triangle([[dots(left + 12), dots(top + 9)], [dots(left + 23), dots(top + 16)],
                             [dots(left + 12), dots(top + 23)]], @theme.text)
    end
  end

  def paint_inspector
    item = @view.selected
    if @view.selected_kind == :zoom
      label("Zoom", INSPECTOR_LEFT, HEADER_TOP + 8, true, @theme.text)
      amount = "#{item.amount.round(2)}x"
      width = @typeface.measure(amount, true)[0] / @scale
      label(amount, AMOUNT_LEFT + (AMOUNT_WIDTH - width) / 2, HEADER_TOP + 8, true, @theme.text)
    else
      label("Clip", INSPECTOR_LEFT, HEADER_TOP + 8, true, @theme.text)
      label("#{item.length.round(1)} s", 356, HEADER_TOP + 8, true, @theme.dim_text)
    end
  end

  def paint_ruler
    (0..@view.duration.to_i).each do |second|
      x = @view.x_at(second.to_f)
      major = second % 5 == 0
      height = major ? 8 : 4
      @canvas.fill_rounded(dots(x), dots(TimelineView::RULER_TOP + TimelineView::RULER_HEIGHT - height), dots(1), dots(height), 0, @theme.tick)
      label(time_text(second.to_f)[0, 5], x + 3, TimelineView::RULER_TOP - 2, false, @theme.dim_text) if major
    end
  end

  def paint_lane(name, top)
    label(name, 16, top + 12, true, @theme.dim_text)
    left = TimelineView::LANE_LEFT
    @canvas.fill_rounded(dots(left), dots(top), dots(TimelineView::LANE_RIGHT - left), dots(TimelineView::LANE_HEIGHT),
                         dots(@theme.radius), @theme.lane)
  end

  # A clip shows the thumbnails of the time it covers.
  def paint_clip(clip)
    left = @view.x_at(clip.start) + 1
    right = @view.x_at(clip.finish) - 1
    top = TimelineView::CLIP_TOP + 3
    height = TimelineView::LANE_HEIGHT - 6
    @canvas.fill_rounded(dots(left), dots(top), dots(right - left), dots(height), dots(6), @theme.well)
    @thumbs.each_index do |slot|
      next unless @thumb_ready[slot]
      slot_left = TimelineView::LANE_LEFT + slot * @thumb_width
      @canvas.blit(@thumbs[slot], @thumb_pixel_width, @thumb_pixel_height, dots(slot_left).to_i, dots(top).to_i,
                   dots(left), dots(right))
    end
    selected = clip.equal?(@view.selected)
    @canvas.stroke_rounded(dots(left), dots(top), dots(right - left), dots(height), dots(6), dots(selected ? 2 : 1),
                           selected ? @theme.outline : @theme.edge)
  end

  def paint_zoom(zoom)
    left = @view.x_at(zoom.start)
    width = [@view.x_at(zoom.finish) - left, 2].max
    top = TimelineView::ZOOM_TOP + 3
    height = TimelineView::LANE_HEIGHT - 6
    selected = zoom.equal?(@view.selected)
    @canvas.fill_rounded(dots(left), dots(top), dots(width), dots(height), dots(6), selected ? @theme.accent_light : @theme.accent)
    @canvas.stroke_rounded(dots(left), dots(top), dots(width), dots(height), dots(6), dots(2), @theme.outline) if selected
    label("#{zoom.amount.round(2)}x", left + 8, top + 9, false, @theme.text) if width > 44
  end

  def slot_time(slot)
    ((slot + 0.5) * @thumb_width / (TimelineView::LANE_RIGHT - TimelineView::LANE_LEFT) * @view.duration).clamp(0.0, @view.duration)
  end

  # Nearest-neighbor shrink of the strip frame, cropped to the thumb's
  # shape around its middle.
  def shrink_into(thumb)
    source_width = @strip.width
    source_height = @strip.height
    scale = [@thumb_pixel_width.to_f / source_width, @thumb_pixel_height.to_f / source_height].max
    offset_x = (source_width * scale - @thumb_pixel_width) / 2
    offset_y = (source_height * scale - @thumb_pixel_height) / 2
    (0...@thumb_pixel_height).each do |y|
      source_y = ((y + offset_y) / scale).to_i.clamp(0, source_height - 1)
      (0...@thumb_pixel_width).each do |x|
        source_x = ((x + offset_x) / scale).to_i.clamp(0, source_width - 1)
        thumb.set_value(:u32, (y * @thumb_pixel_width + x) * 4, @strip_frame.get_value(:u32, (source_y * source_width + source_x) * 4))
      end
    end
  end

  def time_text(seconds)
    format("%02d:%04.1f", seconds.to_i / 60, seconds % 60)
  end
end

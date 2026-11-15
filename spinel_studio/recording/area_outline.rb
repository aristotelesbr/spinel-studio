# The picture of the frame around a recorded area: a thin white line
# just outside the area, with a dark halo so it shows on light screens,
# and stronger corners. The area itself stays transparent.
class AreaOutline
  GAP = 2          # points between the area and the line
  LINE = 2
  HALO = 1
  CORNER = 18
  CORNER_LINE = 4
  BORDER = GAP + CORNER_LINE + HALO   # points the frame reaches past the area

  # area_width x area_height in points; scale is pixels per point;
  # settings: the recording settings (the line's and halo's colors).
  def initialize(area_width, area_height, scale, settings)
    @scale = scale
    @line_color = settings.outline_color
    @halo_color = settings.halo_color
    @width = area_width + 2 * BORDER
    @height = area_height + 2 * BORDER
  end

  def paint
    canvas = Canvas.new((@width * @scale).to_i, (@height * @scale).to_i)
    canvas.clear(0)
    ring(canvas, BORDER - GAP - LINE - HALO, LINE + 2 * HALO, @halo_color)
    ring(canvas, BORDER - GAP - LINE, LINE, @line_color)
    corners(canvas)
    canvas
  end

  private

  # A rectangular band inset from the frame's edge.
  def ring(canvas, inset, thickness, color)
    left = inset
    top = inset
    right = @width - inset
    bottom = @height - inset
    band(canvas, left, top, right - left, thickness, color)
    band(canvas, left, bottom - thickness, right - left, thickness, color)
    band(canvas, left, top, thickness, bottom - top, color)
    band(canvas, right - thickness, top, thickness, bottom - top, color)
  end

  def corners(canvas)
    inset = BORDER - GAP - CORNER_LINE
    far_x = @width - inset
    far_y = @height - inset
    [[inset, inset, 1, 1], [far_x, inset, -1, 1], [inset, far_y, 1, -1], [far_x, far_y, -1, -1]].each do |x, y, across, down|
      band(canvas, across > 0 ? x : x - CORNER, down > 0 ? y : y - CORNER_LINE, CORNER, CORNER_LINE, @line_color)
      band(canvas, across > 0 ? x : x - CORNER_LINE, down > 0 ? y : y - CORNER, CORNER_LINE, CORNER, @line_color)
    end
  end

  def band(canvas, left, top, width, height, color)
    canvas.fill_rounded(left * @scale, top * @scale, width * @scale, height * @scale, 0, color)
  end
end

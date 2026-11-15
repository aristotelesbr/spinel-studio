# The arrow drawn in place of the real cursor, rasterized once at a large
# size: black fill, white outline, soft shadow, antialiased edges. The
# compositor scales it down to the size it needs each frame.
class CursorSprite
  SIZE = 160          # sprite edge in pixels
  ARROW = 120.0       # arrow height in pixels
  MARGIN = 14.0       # room left and above the tip for the outline

  # Arrow outline as fractions of its height, tip first.
  POINTS = [[0.0, 0.0], [0.0, 0.80], [0.19, 0.63], [0.31, 0.92],
            [0.44, 0.86], [0.32, 0.58], [0.56, 0.58]]

  attr_reader :pixels, :hot_x, :hot_y

  # The color at a 16.16 fixed point position, bilinearly sampled.
  def sample(fixed_x, fixed_y)
    last = SIZE - 1
    row_bytes = SIZE * 4
    upper = (fixed_y >> 16) * row_bytes
    lower = [(fixed_y >> 16) + 1, last].min * row_bytes
    left = (fixed_x >> 16) * 4
    right = [(fixed_x >> 16) + 1, last].min * 4
    across = (fixed_x >> 8) & 255
    top = Pixel.mix(@pixels.get_value(:u32, upper + left), @pixels.get_value(:u32, upper + right), across)
    bottom = Pixel.mix(@pixels.get_value(:u32, lower + left), @pixels.get_value(:u32, lower + right), across)
    Pixel.mix(top, bottom, (fixed_y >> 8) & 255)
  end

  # style: the CursorStyle's outline and shadow.
  def initialize(style)
    @outline = style.outline
    @shadow_blur = style.shadow_blur
    @shadow_drop = style.shadow_offset
    @shadow_alpha = style.shadow_opacity
    @hot_x = MARGIN
    @hot_y = MARGIN
    @xs = POINTS.map { |point| MARGIN + point[0] * ARROW }
    @ys = POINTS.map { |point| MARGIN + point[1] * ARROW }
    @edges = @xs.each_index.map { |index| Segment.new(@xs[index - 1], @ys[index - 1], @xs[index], @ys[index]) }
    @pixels = IO::Buffer.new(SIZE * SIZE * 4)
    paint
  end

  private

  def paint
    (0...SIZE).each do |y|
      (0...SIZE).each do |x|
        @pixels.set_value(:u32, (y * SIZE + x) * 4, color_at(x + 0.5, y + 0.5))
      end
    end
  end

  # Black arrow over a white outline over a soft shadow.
  def color_at(x, y)
    distance = distance(x, y)
    black = coverage(-distance)
    white = coverage(@outline - distance)
    shadow = shadow_at(distance(x, y - @shadow_drop))
    alpha = white + shadow * (1.0 - white)
    brightness = alpha > 0 ? white * (1.0 - black) / alpha : 0.0
    level = (brightness * 255).round
    ((alpha * 255).round << 24) | (level << 16) | (level << 8) | level
  end

  def shadow_at(distance)
    return @shadow_alpha if distance < @outline
    return 0.0 if distance >= @outline + @shadow_blur
    fade = 1.0 - (distance - @outline) / @shadow_blur
    @shadow_alpha * fade * fade
  end

  def coverage(distance_inside)
    (distance_inside + 0.5).clamp(0.0, 1.0)
  end

  # Signed distance to the arrow: negative inside, positive outside.
  def distance(x, y)
    nearest = @edges.map { |edge| edge.distance(x, y) }.min
    inside?(x, y) ? -nearest : nearest
  end

  # Even-odd rule: a ray to the right crosses the outline an odd number
  # of times from inside.
  def inside?(x, y)
    corners = @xs.zip(@ys)
    crossings = corners.each_index.count do |index|
      from_x, from_y = corners[index - 1]
      to_x, to_y = corners[index]
      (from_y > y) != (to_y > y) && x < from_x + (y - from_y) * (to_x - from_x) / (to_y - from_y)
    end
    crossings.odd?
  end
end

# A small antialiased painter over a premultiplied BGRA buffer, enough to
# draw the toolbar on a transparent window: rounded rectangles (filled or
# outlined), soft shadows, circles and lines. Text comes from Typeface.
# Coordinates are floats in buffer pixels; colors are 0xAARRGGBB.
class Canvas
  attr_reader :pixels, :width, :height

  def initialize(width, height)
    @width = width
    @height = height
    @pixels = IO::Buffer.new(width * height * 4)
  end

  def clear(color)
    (0...@width * @height).each { |index| @pixels.set_value(:u32, index * 4, color) }
  end

  # Copies an opaque image (source_width x source_height pixels) with its
  # top-left corner at (left, top), showing only columns from_x...to_x.
  def blit(source, source_width, source_height, left, top, from_x, to_x)
    first_x = [left, from_x.ceil, 0].max
    last_x = [left + source_width, to_x.floor, @width].min
    return if first_x >= last_x
    (0...source_height).each do |row|
      y = top + row
      next if y < 0 || y >= @height
      (first_x...last_x).each do |x|
        @pixels.set_value(:u32, (y * @width + x) * 4, source.get_value(:u32, (row * source_width + x - left) * 4))
      end
    end
  end

  def fill_rounded(left, top, width, height, radius, color)
    box = Box.new(left, top, width, height, radius)
    each_pixel_near(box, 0) do |x, y|
      paint(x, y, color, 0.5 - box.distance(x + 0.5, y + 0.5))
    end
  end

  # An outline of the given thickness, inside the rectangle's edge.
  def stroke_rounded(left, top, width, height, radius, thickness, color)
    box = Box.new(left, top, width, height, radius)
    half = thickness / 2.0
    each_pixel_near(box, 0) do |x, y|
      distance_to_band = (box.distance(x + 0.5, y + 0.5) + half).abs - half
      paint(x, y, color, 0.5 - distance_to_band)
    end
  end

  # A shadow under a rounded rectangle, fading out over blur pixels.
  def soft_shadow(left, top, width, height, radius, blur, color)
    box = Box.new(left, top, width, height, radius)
    each_pixel_near(box, blur) do |x, y|
      outside = box.distance(x + 0.5, y + 0.5)
      strength = outside <= 0 ? 1.0 : 1.0 - outside / blur
      paint(x, y, color, strength * strength) if strength > 0
    end
  end

  def circle(center_x, center_y, radius, color)
    fill_rounded(center_x - radius, center_y - radius, 2 * radius, 2 * radius, radius, color)
  end

  # A filled triangle, corners given clockwise on screen.
  def fill_triangle(corners, color)
    fill_polygon(corners, color)
  end

  # A filled convex polygon, corners given clockwise on screen.
  def fill_polygon(corners, color)
    edges = corners.each_index.map { |index| Edge.new(corners[index - 1], corners[index]) }
    xs = corners.map(&:first)
    ys = corners.map(&:last)
    bounds = Box.new(xs.min, ys.min, xs.max - xs.min, ys.max - ys.min, 0)
    each_pixel_near(bounds, 1) do |x, y|
      inside = edges.map { |edge| edge.inside_by(x + 0.5, y + 0.5) }.min
      paint(x, y, color, inside + 0.5)
    end
  end

  def line(from_x, from_y, to_x, to_y, thickness, color)
    segment = Segment.new(from_x, from_y, to_x, to_y)
    half = thickness / 2.0
    bounds = Box.new([from_x, to_x].min, [from_y, to_y].min, (to_x - from_x).abs, (to_y - from_y).abs, 0)
    each_pixel_near(bounds, half) do |x, y|
      paint(x, y, color, half - segment.distance(x + 0.5, y + 0.5) + 0.5)
    end
  end

  private

  def each_pixel_near(box, margin)
    first_x = [(box.left - margin).floor, 0].max
    first_y = [(box.top - margin).floor, 0].max
    last_x = [(box.left + box.width + margin).ceil, @width].min
    last_y = [(box.top + box.height + margin).ceil, @height].min
    (first_y...last_y).each do |y|
      (first_x...last_x).each { |x| yield x, y }
    end
  end

  # Paints color over the pixel ("over" on premultiplied BGRA); coverage
  # (0..1) scales the color's alpha.
  def paint(x, y, color, coverage)
    return if coverage <= 0
    coverage = 1.0 if coverage > 1
    alpha = (((color >> 24) & 255) * coverage).to_i
    return if alpha == 0
    offset = (y * @width + x) * 4
    @pixels.set_value(:u32, offset, Pixel.over(@pixels.get_value(:u32, offset), color, alpha))
  end
end

# A rounded rectangle, measured by signed distance: negative inside.
class Box
  attr_reader :left, :top, :width, :height

  def initialize(left, top, width, height, radius)
    @left = left
    @top = top
    @width = width
    @height = height
    @radius = radius
  end

  def distance(x, y)
    half_width = @width / 2.0
    half_height = @height / 2.0
    across = (x - (@left + half_width)).abs - (half_width - @radius)
    down = (y - (@top + half_height)).abs - (half_height - @radius)
    outside_across = across > 0 ? across : 0.0
    outside_down = down > 0 ? down : 0.0
    inside = [across, down].max
    inside = 0.0 if inside > 0
    Math.sqrt(outside_across * outside_across + outside_down * outside_down) + inside - @radius
  end
end

# A line segment, measured by distance to its nearest point.
class Segment
  def initialize(from_x, from_y, to_x, to_y)
    @from_x = from_x
    @from_y = from_y
    @along_x = to_x - from_x
    @along_y = to_y - from_y
    @length_squared = @along_x * @along_x + @along_y * @along_y
  end

  def distance(x, y)
    offset_x = x - @from_x
    offset_y = y - @from_y
    share = @length_squared > 0 ? (offset_x * @along_x + offset_y * @along_y) / @length_squared : 0.0
    share = share.clamp(0.0, 1.0)
    apart_x = offset_x - @along_x * share
    apart_y = offset_y - @along_y * share
    Math.sqrt(apart_x * apart_x + apart_y * apart_y)
  end
end

# One side of a clockwise polygon: how far a point is on its inner side.
class Edge
  def initialize(from, to)
    @from_x, @from_y = from
    length = Math.sqrt((to[0] - @from_x)**2 + (to[1] - @from_y)**2)
    @normal_x = -(to[1] - @from_y) / length
    @normal_y = (to[0] - @from_x) / length
  end

  def inside_by(x, y)
    (x - @from_x) * @normal_x + (y - @from_y) * @normal_y
  end
end

# Mixing of packed BGRA pixels, two channels per multiply.
module Pixel
  RED_BLUE = 0x00FF00FF
  ALPHA_GREEN = 0xFF00FF00

  # Straight mix of two opaque pixels; weight 0..256 is the share of to.
  def self.mix(from, to, weight)
    keep = 256 - weight
    red_blue = ((((from & RED_BLUE) * keep) + ((to & RED_BLUE) * weight)) >> 8) & RED_BLUE
    alpha_green = ((((from >> 8) & RED_BLUE) * keep) + (((to >> 8) & RED_BLUE) * weight)) & ALPHA_GREEN
    red_blue | alpha_green
  end

  # The average of four pixels.
  def self.average(first, second, third, fourth)
    red_blue = (((first & RED_BLUE) + (second & RED_BLUE) + (third & RED_BLUE) + (fourth & RED_BLUE)) >> 2) & RED_BLUE
    alpha_green = ((((first >> 8) & RED_BLUE) + ((second >> 8) & RED_BLUE) + ((third >> 8) & RED_BLUE) +
                    ((fourth >> 8) & RED_BLUE)) << 6) & ALPHA_GREEN
    red_blue | alpha_green
  end

  # color (straight, 0xAARRGGBB) over a premultiplied pixel, at alpha.
  def self.over(under, color, alpha)
    weight = alpha + (alpha >> 7)
    keep = 256 - weight
    color_red_blue = ((color & RED_BLUE) * weight >> 8) & RED_BLUE
    color_alpha_green = ((0xFF0000 | ((color >> 8) & 0xFF)) * weight) & ALPHA_GREEN
    under_red_blue = ((under & RED_BLUE) * keep >> 8) & RED_BLUE
    under_alpha_green = (((under >> 8) & RED_BLUE) * keep) & ALPHA_GREEN
    (color_red_blue + under_red_blue) | (color_alpha_green + under_alpha_green)
  end
end

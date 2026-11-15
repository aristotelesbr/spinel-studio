# Puts the recording on a wallpaper: a margin, rounded corners and a soft
# drop shadow, with the camera's crop scaled into the window.
#
# What never changes (wallpaper, shadow, corner coverage) is computed
# once. Each frame only rewrites the window's pixels, sampling the
# recording bilinearly in 16.16 fixed point. When the recording is shown
# at less than 1/halve_below of its size, it is first halved by averaging
# 2x2 pixels, so text does not break up.
class Compositor
  ONE = 65536          # 1.0 in 16.16 fixed point
  FULL_COVERAGE = 255

  attr_reader :out, :window_left, :window_top

  # frame_width x frame_height is the captured frame; area_width x
  # area_height the part being shown (the whole frame, or a picked area).
  # halve_below: from the render settings.
  def initialize(frame_width, frame_height, area_width, area_height, out_width, out_height, background, halve_below)
    @halve_below = halve_below
    @frame_width = frame_width
    @frame_height = frame_height
    @out_width = out_width
    @out_height = out_height
    @background = background
    @shadow_blur = background.shadow_blur * out_height / 1080
    padding = background.padding * out_height / 1080
    fit = [(out_width - 2 * padding).to_f / area_width, (out_height - 2 * padding).to_f / area_height].min
    @window_width = (area_width * fit).round
    @window_height = (area_height * fit).round
    @window_left = (out_width - @window_width) / 2
    @window_top = (out_height - @window_height) / 2
    radius = background.rounding * out_height / 1080
    @window = Box.new(@window_left, @window_top, @window_width, @window_height, radius)
    @shadow = Box.new(@window_left, @window_top + background.shadow_offset * out_height / 1080, @window_width, @window_height, radius)
    @half_width = frame_width / 2
    @half_height = frame_height / 2
    @half = IO::Buffer.new(@half_width * @half_height * 4)
    @wallpaper = IO::Buffer.new(out_width * out_height * 4)
    @coverage = IO::Buffer.new(@window_width * @window_height)
    paint_wallpaper
    paint_coverage
    @out = @wallpaper.dup
  end

  # Draws the crop (x, y, width, height in frame pixels) into the window.
  def draw(frame, crop_x, crop_y, crop_width, crop_height)
    if crop_width / @window_width > @halve_below
      halve(frame)
      sample(@half, @half_width, @half_height, crop_x / 2, crop_y / 2, crop_width / 2, crop_height / 2)
    else
      sample(frame, @frame_width, @frame_height, crop_x, crop_y, crop_width, crop_height)
    end
  end

  # Draws the sprite with its hot spot at frame position (x, y) as seen
  # through the crop, height in frame pixels. Clipped to the window, so
  # the next frame rewrites everything it touched.
  def draw_cursor(sprite, x, y, height, crop_x, crop_y, crop_width, crop_height)
    zoom = @window_width / crop_width
    drawn_height = height * zoom
    return if drawn_height < 2
    size = (drawn_height * CursorSprite::SIZE / CursorSprite::ARROW).to_i
    step = (CursorSprite::SIZE * ONE.to_f / size).to_i
    sprite_scale = drawn_height / CursorSprite::ARROW
    left = (@window_left + (x - crop_x) * zoom - sprite.hot_x * sprite_scale).to_i
    top = (@window_top + (y - crop_y) * (@window_height / crop_height) - sprite.hot_y * sprite_scale).to_i
    (0...size).each do |row|
      out_y = top + row
      next if out_y < @window_top || out_y >= @window_top + @window_height
      (0...size).each do |column|
        out_x = left + column
        next if out_x < @window_left || out_x >= @window_left + @window_width
        blend_sprite_pixel(sprite, row * step, column * step, out_x, out_y)
      end
    end
  end

  private

  # The hot loop of the render, written with while and plain integers.
  def sample(frame, source_width, source_height, crop_x, crop_y, crop_width, crop_height)
    step_x = (crop_width * ONE / @window_width).to_i
    step_y = (crop_height * ONE / @window_height).to_i
    first_x = (crop_x * ONE).to_i
    source_y = (crop_y * ONE).to_i
    last_column = source_width - 1
    last_row = source_height - 1
    row_bytes = source_width * 4
    row = 0
    while row < @window_height
      row_above = [source_y >> 16, last_row].min
      upper = row_above * row_bytes
      lower = [row_above + 1, last_row].min * row_bytes
      down = (source_y >> 8) & 255
      target = ((@window_top + row) * @out_width + @window_left) * 4
      coverage_row = row * @window_width
      source_x = first_x
      column = 0
      while column < @window_width
        coverage = @coverage.get_value(:U8, coverage_row + column)
        if coverage != 0
          column_left = [source_x >> 16, last_column].min
          left = column_left * 4
          right = [column_left + 1, last_column].min * 4
          across = (source_x >> 8) & 255
          top = Pixel.mix(frame.get_value(:u32, upper + left), frame.get_value(:u32, upper + right), across)
          bottom = Pixel.mix(frame.get_value(:u32, lower + left), frame.get_value(:u32, lower + right), across)
          color = Pixel.mix(top, bottom, down)
          color = Pixel.mix(@wallpaper.get_value(:u32, target), color, coverage + (coverage >> 7)) if coverage != FULL_COVERAGE
          @out.set_value(:u32, target, color)
        end
        source_x += step_x
        target += 4
        column += 1
      end
      source_y += step_y
      row += 1
    end
  end

  # The frame at half size, each pixel the average of a 2x2 block.
  def halve(frame)
    row_bytes = @frame_width * 4
    row = 0
    while row < @half_height
      upper = row * 2 * row_bytes
      lower = upper + row_bytes
      target = row * @half_width * 4
      column = 0
      while column < @half_width
        left = column * 8
        @half.set_value(:u32, target, Pixel.average(frame.get_value(:u32, upper + left), frame.get_value(:u32, upper + left + 4),
                                                    frame.get_value(:u32, lower + left), frame.get_value(:u32, lower + left + 4)))
        target += 4
        column += 1
      end
      row += 1
    end
  end

  def blend_sprite_pixel(sprite, sprite_y, sprite_x, out_x, out_y)
    coverage = @coverage.get_value(:U8, (out_y - @window_top) * @window_width + (out_x - @window_left))
    return if coverage == 0
    color = sprite.sample(sprite_x, sprite_y)
    alpha = ((color >> 24) & 255) * coverage / FULL_COVERAGE
    return if alpha == 0
    offset = (out_y * @out_width + out_x) * 4
    @out.set_value(:u32, offset, Pixel.mix(@out.get_value(:u32, offset), color, alpha + (alpha >> 7)))
  end

  def paint_wallpaper
    (0...@out_height).each do |y|
      (0...@out_width).each do |x|
        share = (x.to_f / @out_width + y.to_f / @out_height) / 2
        light = 1.0 - @background.shadow * shadow_at(x + 0.5, y + 0.5)
        red, green, blue = [16, 8, 0].map do |shift|
          top = (@background.top_color >> shift) & 255
          bottom = (@background.bottom_color >> shift) & 255
          ((top + (bottom - top) * share) * light).to_i
        end
        @wallpaper.set_value(:u32, (y * @out_width + x) * 4, 0xFF000000 | (red << 16) | (green << 8) | blue)
      end
    end
  end

  def shadow_at(x, y)
    distance = @shadow.distance(x, y)
    return 1.0 if distance <= 0
    return 0.0 if distance >= @shadow_blur
    fade = 1.0 - distance / @shadow_blur
    fade * fade
  end

  # 255 inside the window, 0 past its rounded corners, antialiased edge.
  def paint_coverage
    (0...@window_height).each do |row|
      (0...@window_width).each do |column|
        inside = 0.5 - @window.distance(@window_left + column + 0.5, @window_top + row + 0.5)
        @coverage.set_value(:U8, row * @window_width + column, (inside.clamp(0.0, 1.0) * FULL_COVERAGE).round)
      end
    end
  end
end

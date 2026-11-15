# Marks the picked area on screen while you record: everything outside
# it is lightly dimmed and the AreaOutline frames it. It is one
# transparent window over the whole display that clicks pass through,
# left out of the recording like the bar.
class AreaFrame
  FLAGS = SDL::WINDOW_BORDERLESS | SDL::WINDOW_TRANSPARENT | SDL::WINDOW_ALWAYS_ON_TOP |
          SDL::WINDOW_UTILITY | SDL::WINDOW_NOT_FOCUSABLE

  # settings: the recording settings (the shade and the outline's colors).
  def initialize(settings)
    @settings = settings
    @window = nil
  end

  def number
    @window ? @window.number : 0
  end

  # area in screen pixels.
  def show(area, density)
    hide
    @left, @top, @width, @height = area.map { |pixels| pixels / density }
    screen = SDL.display_size
    @window = Window.new("Spinel Studio frame", screen[0], screen[1], FLAGS, 0)
    @window.move_to(0, 0)
    @window.ignore_mouse
    canvas = AreaOutline.new(@width, @height, @window.scale, @settings).paint
    @outline = @window.texture(canvas.width, canvas.height, true)
    @outline.update(canvas.pixels)
    present
  end

  def present
    return unless @window
    @window.clear(0)
    shade_around_area
    border = AreaOutline::BORDER
    @window.copy(@outline, @left - border, @top - border, @width + 2 * border, @height + 2 * border)
    @window.present
  end

  def hide
    return unless @window
    @window.destroy
    @window = nil
  end

  private

  def shade_around_area
    right = @left + @width
    bottom = @top + @height
    screen_width = @window.width
    screen_height = @window.height
    @window.fill(0, 0, screen_width, @top, @settings.area_shade)
    @window.fill(0, bottom, screen_width, screen_height - bottom, @settings.area_shade)
    @window.fill(0, @top, @left, @height, @settings.area_shade)
    @window.fill(right, @top, screen_width - right, @height, @settings.area_shade)
  end
end

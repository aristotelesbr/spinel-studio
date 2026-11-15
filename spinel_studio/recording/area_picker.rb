# Picks a rectangle of the screen: the screen freezes as a dimmed
# screenshot, you drag the area to record, and Esc or a right click
# cancels. A hint at the top says so.
class AreaPicker < Window
  RIGHT_BUTTON = 3
  HINT = "Drag to select the area  ·  Esc cancels"
  HINT_WIDTH = 330
  HINT_HEIGHT = 40
  HINT_TOP = 48

  # [x, y, width, height] in screen pixels, or [] when the screen could
  # not be captured or the pick was cancelled.
  def self.pick(typeface, settings)
    size = SDL.display_size
    density = Mouse.pixel_density
    screenshot = IO::Buffer.new(size[0] * density * size[1] * density * 4)
    return [] if ScreenCapture.studio_screenshot(screenshot, size[0] * density, size[1] * density) != 0
    picker = AreaPicker.new(typeface, settings, size[0], size[1], density, screenshot)
    picker.show
    picker.destroy
    picker.area
  end

  attr_reader :area

  def initialize(typeface, settings, width, height, density, screenshot)
    super("Spinel Studio area", width, height, SDL::WINDOW_BORDERLESS | SDL::WINDOW_ALWAYS_ON_TOP,
          settings.app.frame_delay_ms)
    @theme = settings.theme
    @shade = settings.recording.picker_shade
    @line_color = settings.recording.outline_color
    @smallest = settings.recording.smallest_area
    move_to(0, 0)
    raise_to_front
    @typeface = typeface
    @density = density
    @screen = texture(width * density, height * density)
    @screen.update(screenshot)
    @hint = texture((HINT_WIDTH * scale).to_i, (HINT_HEIGHT * scale).to_i, true)
    @hint.update(hint_pixels)
    @area = []
    @start_x = @start_y = @end_x = @end_y = 0
    @dragging = false
  end

  def key_down(key, _modifiers)
    close if key == SDL::SCANCODE_ESCAPE
  end

  def mouse_down(x, y, button)
    return close if button == RIGHT_BUTTON
    @start_x = @end_x = x
    @start_y = @end_y = y
    @dragging = true
  end

  def mouse_move(x, y)
    return unless @dragging
    @end_x = x
    @end_y = y
  end

  # A drag big enough is the area; a smaller one starts over.
  def mouse_up(_x, _y, _button)
    return unless @dragging
    @dragging = false
    selection = selection_points
    return unless selection[2] >= @smallest && selection[3] >= @smallest
    @area = selection.map { |points| points * @density }
    close
  end

  def draw
    copy(@screen, 0, 0, width, height)
    return draw_selection if @dragging
    fill(0, 0, width, height, @shade)
    copy(@hint, (width - HINT_WIDTH) / 2, HINT_TOP, HINT_WIDTH, HINT_HEIGHT)
  end

  private

  def selection_points
    [[@start_x, @end_x].min, [@start_y, @end_y].min, (@end_x - @start_x).abs, (@end_y - @start_y).abs]
  end

  # Shade around the selection, and a white frame on its edge.
  def draw_selection
    left, top, area_width, area_height = selection_points
    right = left + area_width
    bottom = top + area_height
    fill(0, 0, width, top, @shade)
    fill(0, bottom, width, height - bottom, @shade)
    fill(0, top, left, area_height, @shade)
    fill(right, top, width - right, area_height, @shade)
    outline(left, top, area_width, area_height, 1, @line_color)
    outline(left, top, area_width, area_height, 2, @line_color)
  end

  def hint_pixels
    canvas = Canvas.new((HINT_WIDTH * scale).to_i, (HINT_HEIGHT * scale).to_i)
    canvas.clear(0)
    canvas.fill_rounded(0, 0, canvas.width, canvas.height, canvas.height / 2.0, @theme.surface)
    size = @typeface.measure(HINT, false)
    @typeface.draw(canvas, HINT, (canvas.width - size[0]) / 2, (canvas.height - size[1]) / 2, false, @theme.text)
    canvas.pixels
  end
end

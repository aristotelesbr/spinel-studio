# The floating bar: a rounded pill with a soft shadow on a transparent
# window. Every button is the same rounded square; hovering fades a
# highlight in, pressing shrinks the icon a little. While recording, the
# stop button and the dot beside the time pulse.
#
# Layout numbers are points inside the pill; the window adds a margin
# around it for the shadow, and #dots turns points into pixels.
class Toolbar
  MARGIN = 16
  PILL_WIDTH = 300
  PILL_HEIGHT = 56
  WIDTH = PILL_WIDTH + 2 * MARGIN
  HEIGHT = PILL_HEIGHT + 2 * MARGIN
  PILL_RADIUS = 16
  BUTTON_SIZE = 40
  BUTTON_RADIUS = 10
  BUTTON_TOP = 8
  TIMER_LEFT = 152
  TIMER_WIDTH = 84
  SEPARATORS = [100, 244]

  # The buttons (:display, :area, :record, :close) and where they sit.
  BUTTON_LEFT = { display: 8, area: 52, record: 108, close: 252 }.freeze


  ICON_CENTER = 20

  # mode: :display or :area. state: the RecordingSession's (:idle,
  # :countdown, :recording). hover, pressed: a button or :none.
  attr_accessor :mode, :state, :hover, :pressed, :seconds

  # typeface: anything with measure(text, large) and
  # draw(canvas, text, x, y, large, color), sized for this scale. theme:
  # the colors; settings: the toolbar settings (animation speeds).
  def initialize(scale, typeface, theme, settings)
    @scale = scale.to_f
    @typeface = typeface
    @theme = theme
    @hover_fade_speed = settings.hover_fade_speed
    @pulse_speed = settings.pulse_speed
    @pressed_icon_scale = settings.pressed_icon_scale
    @canvas = Canvas.new(dots(WIDTH).to_i, dots(HEIGHT).to_i)
    @backdrop = nil
    @mode = :display
    @state = :idle
    @hover = :none
    @pressed = :none
    @seconds = 0
    @highlight = { display: 0.0, area: 0.0, record: 0.0, close: 0.0 }
    @clock = 0.0
    @icon_left = 0.0
    @icon_top = 0.0
    @icon_scale = 1.0
  end

  def pixels
    @canvas.pixels
  end

  def pixel_width
    @canvas.width
  end

  def pixel_height
    @canvas.height
  end

  # The button under a point of the window (in points), or :none.
  def button_at(x, y)
    inside_x = x - MARGIN
    inside_y = y - MARGIN
    return :none if inside_y < BUTTON_TOP || inside_y >= BUTTON_TOP + BUTTON_SIZE
    found = BUTTON_LEFT.find { |_button, left| inside_x >= left && inside_x < left + BUTTON_SIZE }
    found ? found[0] : :none
  end

  def enabled?(button)
    return true if button == :close
    return button == :record if @state == :recording
    @state == :idle
  end

  # Advances the hover fades and the pulse; true while something moves.
  def animate(elapsed)
    @clock += elapsed
    moving = @state == :recording || @state == :countdown
    @highlight.each_key do |button|
      target = button == @hover && enabled?(button) ? 1.0 : 0.0
      level = @highlight[button]
      next if level == target
      step = elapsed * @hover_fade_speed
      @highlight[button] = target > level ? [level + step, target].min : [level - step, target].max
      moving = true
    end
    moving
  end

  def paint
    @backdrop ||= paint_backdrop
    @canvas.pixels.copy(@backdrop)
    BUTTON_LEFT.each { |button, left| paint_button(button, left) }
    paint_timer
  end

  private

  def dots(points)
    points * @scale
  end

  # The pill, its shadow and the separators never change: painted once.
  def paint_backdrop
    @canvas.clear(0)
    paint_pill
    @canvas.pixels.dup
  end

  def paint_pill
    left = dots(MARGIN)
    @canvas.soft_shadow(left, left + dots(4), dots(PILL_WIDTH), dots(PILL_HEIGHT), dots(PILL_RADIUS), dots(14), @theme.shadow)
    @canvas.fill_rounded(left, left, dots(PILL_WIDTH), dots(PILL_HEIGHT), dots(PILL_RADIUS), @theme.surface)
    @canvas.stroke_rounded(left, left, dots(PILL_WIDTH), dots(PILL_HEIGHT), dots(PILL_RADIUS), dots(1), @theme.edge)
    SEPARATORS.each do |x|
      @canvas.fill_rounded(dots(MARGIN + x), dots(MARGIN + 18), dots(1), dots(20), 0, @theme.separator)
    end
  end

  def paint_button(button, left)
    x = dots(MARGIN + left)
    y = dots(MARGIN + BUTTON_TOP)
    size = dots(BUTTON_SIZE)
    radius = dots(BUTTON_RADIUS)
    @canvas.fill_rounded(x, y, size, size, radius, @theme.selected) if selected?(button)
    level = @highlight[button]
    @canvas.fill_rounded(x, y, size, size, radius, faded(@theme.hover, level)) if level > 0
    held = button == @pressed && button == @hover && enabled?(button)
    @canvas.fill_rounded(x, y, size, size, radius, @theme.press) if held
    @icon_left = MARGIN + left
    @icon_top = MARGIN + BUTTON_TOP
    @icon_scale = held ? @pressed_icon_scale : 1.0
    paint_icon(button)
  end

  def selected?(button)
    (button == :display || button == :area) && button == @mode
  end

  def paint_icon(button)
    color = enabled?(button) || (selected?(button) && @state == :idle) ? @theme.text : @theme.faint_text
    case button
    when :display then display_icon(color)
    when :area then area_icon(color)
    when :record then record_icon
    else close_icon(color)
    end
  end

  def faded(color, level)
    Theme.faded(color, level)
  end

  def pulse
    (Math.sin(@clock * @pulse_speed) + 1) / 2
  end

  # Icons are drawn on a 40-point grid, scaled about its center.
  def icon_x(position)
    dots(@icon_left + ICON_CENTER + (position - ICON_CENTER) * @icon_scale)
  end

  def icon_y(position)
    dots(@icon_top + ICON_CENTER + (position - ICON_CENTER) * @icon_scale)
  end

  def icon_length(length)
    dots(length * @icon_scale)
  end

  def display_icon(color)
    @canvas.stroke_rounded(icon_x(9), icon_y(11), icon_length(22), icon_length(15), icon_length(3), icon_length(2), color)
    @canvas.fill_rounded(icon_x(18.5), icon_y(26), icon_length(3), icon_length(4), 0, color)
    @canvas.fill_rounded(icon_x(14), icon_y(29), icon_length(12), icon_length(2), icon_length(1), color)
  end

  CORNERS = [[10, 10, 1, 1], [30, 10, -1, 1], [10, 30, 1, -1], [30, 30, -1, -1]]
  CORNER_ARM = 6

  def area_icon(color)
    CORNERS.each do |x, y, across, down|
      @canvas.line(icon_x(x), icon_y(y), icon_x(x + CORNER_ARM * across), icon_y(y), icon_length(2), color)
      @canvas.line(icon_x(x), icon_y(y), icon_x(x), icon_y(y + CORNER_ARM * down), icon_length(2), color)
    end
  end

  def record_icon
    case @state
    when :recording
      @canvas.circle(icon_x(20), icon_y(20), icon_length(14), faded(@theme.red, 0.15 + 0.25 * pulse))
      @canvas.fill_rounded(icon_x(13), icon_y(13), icon_length(14), icon_length(14), icon_length(4), @theme.red)
    else
      @canvas.circle(icon_x(20), icon_y(20), icon_length(13), @theme.red_ring)
      @canvas.circle(icon_x(20), icon_y(20), icon_length(9 + @highlight[:record]), @theme.red)
    end
  end

  def close_icon(color)
    @canvas.line(icon_x(14), icon_y(14), icon_x(26), icon_y(26), icon_length(2), color)
    @canvas.line(icon_x(26), icon_y(14), icon_x(14), icon_y(26), icon_length(2), color)
  end

  # The well beside the record button: the time while recording, 3-2-1
  # before it.
  def paint_timer
    left = dots(MARGIN + TIMER_LEFT)
    top = dots(MARGIN + BUTTON_TOP)
    width = dots(TIMER_WIDTH)
    height = dots(BUTTON_SIZE)
    @canvas.fill_rounded(left, top, width, height, dots(BUTTON_RADIUS), @theme.well)
    paint_time(left, top, width, height)
  end

  def paint_time(left, top, width, height)
    large = @state == :countdown
    label = large ? @seconds.to_s : clock_label
    size = @typeface.measure(label, large)
    text_left = left + (width - size[0]) / 2
    if @state == :recording
      text_left += dots(5)
      @canvas.circle(text_left - dots(9), top + height / 2, dots(3), faded(@theme.red, 0.5 + 0.5 * pulse))
    end
    @typeface.draw(@canvas, label, text_left.to_i, (top + (height - size[1]) / 2).to_i, large,
                   @state == :idle ? @theme.faint_text : @theme.text)
  end

  def clock_label
    format("%02d:%02d", @seconds / 60, @seconds % 60)
  end
end

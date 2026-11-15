# The app: the floating bar to pick Display or Area and record. The
# RecordingSession runs the countdown and the take; the bar (and the
# frame around a picked area) stays on screen but out of the video,
# showing the time and the stop button. The recording settings' stop
# shortcut (Control+Option+S) also stops.
# The take then opens in the editor.
class App < Window
  FLAGS = SDL::WINDOW_BORDERLESS | SDL::WINDOW_TRANSPARENT | SDL::WINDOW_ALWAYS_ON_TOP |
          SDL::WINDOW_UTILITY | SDL::WINDOW_NOT_FOCUSABLE

  def initialize(settings)
    super("Spinel Studio", Toolbar::WIDTH, Toolbar::HEIGHT, FLAGS, settings.app.frame_delay_ms)
    @settings = settings
    toolbar = settings.toolbar
    @hide_wait_ms = toolbar.hide_wait_ms
    @stop_keys = Mouse.key_groups(settings.recording.stop_shortcut)
    screen = SDL.display_size
    @screen_width = screen[0]
    @screen_height = screen[1]
    @x = (@screen_width - Toolbar::WIDTH) / 2
    @y = @screen_height - Toolbar::HEIGHT - toolbar.bottom_gap
    move_to(@x, @y)
    @typeface = Typeface.new(toolbar.timer_text_size * scale, toolbar.countdown_text_size * scale, settings.theme.font)
    @bar = Toolbar.new(scale, @typeface, settings.theme, toolbar)
    @bar_texture = texture(@bar.pixel_width, @bar.pixel_height, true)
    @session = RecordingSession.new(settings.recording)
    @area = []
    @frame = AreaFrame.new(settings.recording)
    @dragging = false
    @drag_x = 0
    @drag_y = 0
    @dirty = true
    @last_update = SpinelStudio.now
  end

  # Runs the bar; a take still running when it closes is saved.
  def show
    super
    @session.stop if @session.recording?
    @frame.hide
  end

  def mouse_move(x, y)
    return follow_drag if @dragging
    @bar.hover = @bar.button_at(x, y)
    @dirty = true
  end

  # A press on the bar's empty space drags the bar.
  def mouse_down(x, y, _button)
    @bar.pressed = @bar.button_at(x, y)
    start_drag if @bar.pressed == :none
    @dirty = true
  end

  def mouse_up(x, y, _button)
    @dragging = false
    button = @bar.button_at(x, y)
    pressed = @bar.pressed
    @bar.pressed = :none
    @dirty = true
    click(button) if button != :none && button == pressed
  end

  def update
    now = SpinelStudio.now
    @session.tick(now, @area, excluded_windows)
    stop_recording if @session.recording? && stop_keys_down?
    @bar.state = @session.state
    @bar.seconds = @session.seconds
    @dirty = true if @bar.animate(now - @last_update)
    @last_update = now
  end

  def needs_redraw?
    @dirty
  end

  def draw
    @frame.present
    @bar.paint
    @bar_texture.update(@bar.pixels)
    clear(0)
    copy(@bar_texture, 0, 0, width, height)
    @dirty = false
  end

  private

  def click(button)
    return close if button == :close
    return unless @bar.enabled?(button)
    case button
    when :display then pick_display
    when :area then pick_area
    when :record then @session.recording? ? stop_recording : @session.start_countdown(SpinelStudio.now)
    end
  end

  def pick_display
    @bar.mode = :display
    @area = []
    @frame.hide
  end

  # The bar hides while the screen is captured for the picker.
  def pick_area
    @frame.hide
    hide
    wait(@hide_wait_ms)
    picked = AreaPicker.pick(@typeface, @settings)
    unless picked.empty?
      @area = picked
      @bar.mode = :area
      move_outside(picked)
    end
    show_frame
    reveal
  end

  # Keeps the bar off the area when it can (it is left out of the video
  # anyway, but it would hide what you are recording).
  def move_outside(area)
    density = Mouse.pixel_density
    left, top, area_width, area_height = area.map { |pixels| pixels / density }
    overlaps = @x < left + area_width && @x + width > left && @y < top + area_height && @y + height > top
    return unless overlaps
    if top + area_height + height < @screen_height
      @y = top + area_height
    elsif top - height > 0
      @y = top - height
    end
    @x = (left + (area_width - width) / 2).clamp(0, @screen_width - width)
    move_to(@x, @y)
  end

  # The marks around a picked area; the bar stays above them.
  def show_frame
    return if @area.empty?
    @frame.show(@area, Mouse.pixel_density)
    raise_to_front
  end

  def excluded_windows
    [number, @frame.number].reject(&:zero?)
  end

  # The take opens in the editor; the bar comes back when it closes.
  def stop_recording
    dir = @session.stop
    hide
    @frame.hide
    editor = Editor.new(dir, @settings)
    editor.show
    editor.destroy
    reveal
    show_frame
    @dirty = true
  end

  def stop_keys_down?
    Mouse.held?(@stop_keys)
  end

  def start_drag
    pointer = SDL.global_mouse
    @drag_x = pointer[0] - @x
    @drag_y = pointer[1] - @y
    @dragging = true
  end

  def follow_drag
    pointer = SDL.global_mouse
    @x = pointer[0] - @drag_x
    @y = pointer[1] - @drag_y
    move_to(@x, @y)
  end
end

# The export in progress: a small window with the file's name, a bar,
# the percentage and a Cancel button (or the cancel shortcut), in the
# theme's dialog font, as macOS dialogs read. It runs
# its own loop, so the editor behind it takes no input and stays dimmed
# until the video is done or the export is cancelled.
class ExportWindow < Window
  WIDTH = 420
  HEIGHT = 140
  MARGIN = 24
  TITLE_TOP = 20
  NAME_TOP = 48
  BAR_TOP = 76
  BAR_HEIGHT = 6
  BUTTON_TOP = 96
  BUTTON_WIDTH = 104
  BUTTON_HEIGHT = 30
  TITLE = "Exporting video"

  # Exports to the end; :done, or :cancelled when stopped.
  def self.run(exporter, settings)
    window = ExportWindow.new(exporter, settings)
    window.show
    window.destroy
    window.result
  end

  attr_reader :result

  def initialize(exporter, settings)
    super(TITLE, WIDTH, HEIGHT, 0, settings.app.frame_delay_ms)
    raise_to_front
    @exporter = exporter
    @theme = settings.theme
    @slice = settings.editor.export_slice
    @progress_step = settings.editor.progress_step
    @shortcuts = settings.editor.shortcuts
    @typeface = Typeface.new(@theme.small_text_size * scale, @theme.text_size * scale, @theme.dialog_font)
    @canvas = Canvas.new((WIDTH * scale).to_i, (HEIGHT * scale).to_i)
    @picture = texture(@canvas.width, @canvas.height)
    @cancel = Button.new(WIDTH - MARGIN - BUTTON_WIDTH, BUTTON_TOP, BUTTON_WIDTH, BUTTON_HEIGHT, "Cancel",
                         :secondary, :cancel)
    @name = File.basename(exporter.path)
    @hovered = false
    @held = false
    @shown_progress = -1.0
    @result = :running
  end

  def update
    return unless @result == :running
    finish(:done) unless @exporter.work(@slice)
  end

  def needs_redraw?
    @exporter.progress - @shown_progress >= @progress_step || @shown_progress < 0
  end

  def draw
    @shown_progress = @exporter.progress
    paint
    @picture.update(@canvas.pixels)
    copy(@picture, 0, 0, WIDTH, HEIGHT)
  end

  def mouse_move(x, y)
    hovered = @cancel.contains?(x, y)
    return if hovered == @hovered
    @hovered = hovered
    @shown_progress = -1.0
  end

  def mouse_down(x, y, _button)
    @held = @cancel.contains?(x, y)
    @shown_progress = -1.0
  end

  def mouse_up(x, y, _button)
    clicked = @held && @cancel.contains?(x, y)
    @held = false
    @shown_progress = -1.0
    finish(:cancelled) if clicked
  end

  def key_down(key, modifiers)
    action = @shortcuts.action_for(SDL.SDL_GetScancodeName(key), (modifiers & Editor::COMMAND) != 0,
                                   (modifiers & Editor::SHIFT) != 0, (modifiers & Editor::OPTION) != 0)
    finish(:cancelled) if action == :cancel
  end

  # Closing the window cancels the export.
  def close_requested
    finish(:cancelled)
  end

  private

  def finish(result)
    @result = result
    close
  end

  def dots(points)
    points * scale
  end

  def paint
    progress = @exporter.progress
    @canvas.clear(@theme.panel)
    label(TITLE, MARGIN, TITLE_TOP, true, @theme.text)
    percent = "#{(progress * 100).to_i}%"
    label(percent, WIDTH - MARGIN - @typeface.measure(percent, true)[0] / scale, TITLE_TOP, true, @theme.text)
    label(fitted(@name, WIDTH - 2 * MARGIN), MARGIN, NAME_TOP, false, @theme.dim_text)
    bar_width = WIDTH - 2 * MARGIN
    @canvas.fill_rounded(dots(MARGIN), dots(BAR_TOP), dots(bar_width), dots(BAR_HEIGHT), dots(BAR_HEIGHT / 2.0), @theme.lane)
    filled = BAR_HEIGHT + (bar_width - BAR_HEIGHT) * progress
    @canvas.fill_rounded(dots(MARGIN), dots(BAR_TOP), dots(filled), dots(BAR_HEIGHT), dots(BAR_HEIGHT / 2.0), @theme.accent)
    @cancel.paint(@canvas, @typeface, @theme, scale, @hovered, @held)
  end

  def label(text, x, y, large, color)
    @typeface.draw(@canvas, text, dots(x).to_i, dots(y).to_i, large, color)
  end

  # text cut with an ellipsis until it fits width points.
  def fitted(text, width)
    shown = text
    while shown.size > 1 && @typeface.measure(shown, false)[0] / scale > width
      shown = shown[0, shown.size - 2] + "…"
    end
    shown
  end
end

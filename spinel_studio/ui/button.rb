# A text button of the editor, in one of three variants: :primary (the
# accent, for the main action), :secondary (a well) and :danger (red
# text). It names the editor action it performs, as a shortcut key does.
# Hovering lightens it and pressing darkens it, as in the toolbar. A
# button with a keyboard shortcut shows its key in a small keycap after
# the label. Positions are points.
class Button
  KEYCAP_HEIGHT = 16
  KEYCAP_PADDING = 4
  KEYCAP_GAP = 6
  KEYCAP_RADIUS = 4

  attr_reader :left, :top, :width, :height, :action
  attr_accessor :label, :enabled

  # shortcut: the key that does the same, as shown ("" for none).
  def initialize(left, top, width, height, label, variant, action, shortcut = "")
    @left = left
    @top = top
    @width = width
    @height = height
    @label = label
    @variant = variant
    @action = action
    @shortcut = shortcut
    @enabled = true
  end

  def contains?(x, y)
    @enabled && x >= @left && x < @left + @width && y >= @top && y < @top + @height
  end

  # hovered and held tell how the pointer is on it.
  def paint(canvas, typeface, theme, scale, hovered, held)
    @theme = theme
    left = @left * scale
    top = @top * scale
    width = @width * scale
    height = @height * scale
    radius = theme.radius * scale
    canvas.fill_rounded(left, top, width, height, radius, fill)
    canvas.fill_rounded(left, top, width, height, radius, theme.hover) if hovered && @enabled
    canvas.fill_rounded(left, top, width, height, radius, theme.press) if held && @enabled
    size = typeface.measure(@label, true)
    return paint_with_keycap(canvas, typeface, scale, size) unless @shortcut.empty?
    typeface.draw(canvas, @label, (left + (width - size[0]) / 2).to_i, (top + (height - size[1]) / 2).to_i, true, text_color)
  end

  private

  def paint_with_keycap(canvas, typeface, scale, label_size)
    key_size = typeface.measure(@shortcut, false)
    cap_width = key_size[0] + 2 * KEYCAP_PADDING * scale
    cap_height = KEYCAP_HEIGHT * scale
    x = @left * scale + (@width * scale - label_size[0] - KEYCAP_GAP * scale - cap_width) / 2
    middle = (@top + @height / 2.0) * scale
    typeface.draw(canvas, @label, x.to_i, (middle - label_size[1] / 2).to_i, true, text_color)
    cap_left = x + label_size[0] + KEYCAP_GAP * scale
    canvas.fill_rounded(cap_left, middle - cap_height / 2, cap_width, cap_height, KEYCAP_RADIUS * scale, @theme.hover)
    typeface.draw(canvas, @shortcut, (cap_left + KEYCAP_PADDING * scale).to_i, (middle - key_size[1] / 2).to_i, false, keycap_color)
  end

  def keycap_color
    @enabled ? @theme.dim_text : @theme.faint_text
  end

  def fill
    return @theme.well unless @enabled
    @variant == :primary ? @theme.accent : @theme.well
  end

  def text_color
    return @theme.faint_text unless @enabled
    @variant == :danger ? @theme.red : @theme.text
  end
end

# The look shared by the bar, the editor and the area picker, from the
# "theme" section of the settings: the fonts (the editor's, and the
# dialogs'), text sizes, corner radii and every color (0xAARRGGBB once
# read).
class Theme
  attr_reader :font, :dialog_font, :text_size, :small_text_size, :radius, :large_radius,
              :window, :panel, :surface, :lane, :well, :selected, :edge, :shadow, :separator, :tick,
              :text, :dim_text, :faint_text, :accent, :accent_light, :red, :red_ring, :outline,
              :hover, :press, :playhead, :modal_shade

  def initialize(data)
    @font = FontChoice.new(data["font"])
    @dialog_font = FontChoice.new(data["dialogFont"])
    @text_size = data["textSize"].to_i
    @small_text_size = data["smallTextSize"].to_i
    @radius = data["radius"].to_i
    @large_radius = data["largeRadius"].to_i
    read_colors(data["colors"])
  end

  # color with its alpha scaled by share (0..1).
  def self.faded(color, share)
    alpha = (((color >> 24) & 255) * share).to_i
    (alpha << 24) | (color & 0xFFFFFF)
  end

  private

  def read_colors(colors)
    @window = Color.parse(colors["window"].to_s)
    @panel = Color.parse(colors["panel"].to_s)
    @surface = Color.parse(colors["surface"].to_s)
    @lane = Color.parse(colors["lane"].to_s)
    @well = Color.parse(colors["well"].to_s)
    @selected = Color.parse(colors["selected"].to_s)
    @edge = Color.parse(colors["edge"].to_s)
    @shadow = Color.parse(colors["shadow"].to_s)
    @separator = Color.parse(colors["separator"].to_s)
    @tick = Color.parse(colors["tick"].to_s)
    @text = Color.parse(colors["text"].to_s)
    @dim_text = Color.parse(colors["dimText"].to_s)
    @faint_text = Color.parse(colors["faintText"].to_s)
    @accent = Color.parse(colors["accent"].to_s)
    @accent_light = Color.parse(colors["accentLight"].to_s)
    @red = Color.parse(colors["red"].to_s)
    @red_ring = Color.parse(colors["redRing"].to_s)
    @outline = Color.parse(colors["outline"].to_s)
    @hover = Color.parse(colors["hover"].to_s)
    @press = Color.parse(colors["press"].to_s)
    @playhead = Color.parse(colors["playhead"].to_s)
    @modal_shade = Color.parse(colors["modalShade"].to_s)
  end
end

# A font file and the name of the weight to use from it.
class FontChoice
  attr_reader :path, :weight

  def initialize(data)
    @path = data["path"].to_s
    @weight = data["weight"].to_s
  end
end

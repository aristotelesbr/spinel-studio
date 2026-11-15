require "json"

# How the recording on the wallpaper looks: margin, corner rounding,
# shadow strength, blur and offset, and the two gradient colors.
class Background
  attr_reader :padding, :rounding, :shadow, :shadow_blur, :shadow_offset, :top_color, :bottom_color

  def initialize(settings)
    @padding = settings["padding"].to_i
    @rounding = settings["rounding"].to_i
    @shadow = settings["shadow"].to_f
    @shadow_blur = settings["shadowBlur"].to_f
    @shadow_offset = settings["shadowOffset"].to_i
    @top_color = Background.color(settings["gradient"][0].to_s)
    @bottom_color = Background.color(settings["gradient"][1].to_s)
  end

  def self.color(hex)
    hex.delete("#").to_i(16)
  end

  def to_h
    { "padding" => @padding, "rounding" => @rounding, "shadow" => @shadow,
      "shadowBlur" => @shadow_blur, "shadowOffset" => @shadow_offset,
      "gradient" => [format("#%06X", @top_color), format("#%06X", @bottom_color)] }
  end
end

# The drawn cursor: its height in screen pixels, the spring stiffness
# that smooths its path (lower is smoother), how much tighter the spring
# gets around a click (from click_before seconds before it to
# click_after after), how far and how long the arrow dips on one, and
# the arrow's white outline and shadow (in pixels of a 120-pixel arrow).
class CursorStyle
  attr_reader :size, :smoothing, :click_grip, :click_before, :click_after, :click_dip, :click_dip_length,
              :outline, :shadow_blur, :shadow_offset, :shadow_opacity

  def initialize(settings)
    @size = settings["size"].to_f
    @smoothing = settings["smoothing"].to_f
    @click_grip = settings["clickGrip"].to_f
    @click_before = settings["clickWindow"][0].to_f
    @click_after = settings["clickWindow"][1].to_f
    @click_dip = settings["clickDip"].to_f
    @click_dip_length = settings["clickDipLength"].to_f
    @outline = settings["outline"].to_f
    @shadow_blur = settings["shadowBlur"].to_f
    @shadow_offset = settings["shadowOffset"].to_f
    @shadow_opacity = settings["shadowOpacity"].to_f
  end

  def to_h
    { "size" => @size, "smoothing" => @smoothing, "clickGrip" => @click_grip,
      "clickWindow" => [@click_before, @click_after], "clickDip" => @click_dip,
      "clickDipLength" => @click_dip_length, "outline" => @outline, "shadowBlur" => @shadow_blur,
      "shadowOffset" => @shadow_offset, "shadowOpacity" => @shadow_opacity }
  end
end

# How the zoomed view follows the cursor: the pan spring's stiffness and
# the share of the view the cursor roams without a pan.
class CameraStyle
  attr_reader :follow, :comfort

  def initialize(settings)
    @follow = settings["follow"].to_f
    @comfort = settings["comfort"].to_f
  end

  def to_h
    { "follow" => @follow, "comfort" => @comfort }
  end
end

# Zooms: the amount of a new one, the seconds it takes to ease in and
# out, and how the zooms made from clicks are placed (fully in lead
# seconds before a click, held hold seconds after the last one, one zoom
# for clicks within join_within seconds).
class ZoomStyle
  attr_reader :amount, :ramp, :lead, :hold, :join_within

  def initialize(settings)
    @amount = settings["amount"].to_f
    @ramp = settings["ramp"].to_f
    @lead = settings["lead"].to_f
    @hold = settings["hold"].to_f
    @join_within = settings["joinWithin"].to_f
  end

  def to_h
    { "amount" => @amount, "ramp" => @ramp, "lead" => @lead, "hold" => @hold, "joinWithin" => @join_within }
  end
end

# A take's edits, in project-config.json beside the recording (the file
# Cap keeps for the same purpose): background, cursor, camera, zoom and
# timeline. A take saved before a setting existed takes it from the
# defaults.
class ProjectConfig
  FILE = "project-config.json"

  attr_reader :background, :cursor, :camera, :zoom, :timeline

  def initialize(data, timeline)
    @background = Background.new(data["background"])
    @cursor = CursorStyle.new(data["cursor"])
    @camera = CameraStyle.new(data["camera"])
    @zoom = ZoomStyle.new(data["zoom"])
    @timeline = timeline
  end

  # The take's project, or a new one from the defaults, kept within the
  # recording's duration.
  def self.open(dir, defaults, duration, clicks)
    path = "#{dir}/#{FILE}"
    project = File.exist?(path) ? parse(Settings.merged(defaults, JSON.parse(File.read(path)))) : fresh(defaults, duration, clicks)
    project.timeline.fit(duration)
    project
  end

  def self.fresh(defaults, duration, clicks)
    ProjectConfig.new(defaults, Timeline.fresh(duration, clicks, ZoomStyle.new(defaults["zoom"])))
  end

  def self.parse(data)
    timeline = data["timeline"]
    clips = timeline["segments"].map { |clip| Span.new(clip["start"].to_f, clip["end"].to_f) }
    zooms = timeline["zoomSegments"].map { |zoom| Span.new(zoom["start"].to_f, zoom["end"].to_f, zoom["amount"].to_f) }
    ProjectConfig.new(data, Timeline.new(clips, zooms))
  end

  def save(dir)
    File.write("#{dir}/#{FILE}", JSON.pretty_generate(to_h) + "\n")
  end

  def to_h
    { "background" => @background.to_h, "cursor" => @cursor.to_h, "camera" => @camera.to_h, "zoom" => @zoom.to_h,
      "timeline" => { "segments" => @timeline.clips.map { |clip| span_h(clip) },
                      "zoomSegments" => @timeline.zooms.map { |zoom| span_h(zoom).merge("amount" => zoom.amount) } } }
  end

  private

  def span_h(span)
    { "start" => span.start.round(3), "end" => span.finish.round(3) }
  end
end

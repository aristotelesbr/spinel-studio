require "json"

# Every setting of the app: config/application.json (shipped inside the
# app), with the user's own settings.json laid over it. Each section of
# the file has a reader object here, so code asks settings.editor.edge_grab
# and never reads the JSON itself. Values a new project starts from live
# under "project"; each take then keeps its own copy in project-config.json.
class Settings
  USER_FILE = File.expand_path("~/Library/Application Support/Spinel Studio/settings.json")
  DEVELOPMENT_FILE = File.expand_path("../config/application.json", __dir__)

  attr_reader :app, :theme, :toolbar, :recording, :export, :editor, :render

  def self.load
    defaults = JSON.parse(File.read(defaults_file))
    user = File.exist?(USER_FILE) ? JSON.parse(File.read(USER_FILE)) : {}
    Settings.new(merged(defaults, user))
  end

  # Inside the app bundle the file sits in Contents/Resources.
  def self.defaults_file
    bundled = File.expand_path("../Resources/application.json", File.dirname(File.expand_path($0)))
    File.exist?(bundled) ? bundled : DEVELOPMENT_FILE
  end

  def self.merged(base, over)
    result = base.dup
    over.each do |key, value|
      result[key] = base[key].is_a?(Hash) && value.is_a?(Hash) ? merged(base[key], value) : value
    end
    result
  end

  def initialize(data)
    @data = data
    @app = AppSettings.new(data["app"])
    @theme = Theme.new(data["theme"])
    @toolbar = ToolbarSettings.new(data["toolbar"])
    @recording = RecordingSettings.new(data["recording"])
    @export = ExportSettings.new(data["export"])
    @editor = EditorSettings.new(data["editor"], data["project"]["zoom"]["amount"].to_f)
    @render = RenderSettings.new(data["render"])
  end

  # The "project" section, as a new project's starting point.
  def project_defaults
    @data["project"]
  end
end

# Colors in the settings are CSS hex, #RRGGBB or #RRGGBBAA; the program
# draws with 0xAARRGGBB.
module Color
  def self.parse(hex)
    digits = hex.delete("#")
    value = digits.to_i(16)
    return 0xFF000000 | value if digits.size == 6
    ((value & 0xFF) << 24) | (value >> 8)
  end
end

# "app": the tools the program runs, where macOS keeps its cursors, and
# its windows' frame pace.
class AppSettings
  attr_reader :ffmpeg, :ffprobe, :system_cursors, :frame_delay_ms

  def initialize(data)
    @system_cursors = data["systemCursors"].map(&:to_s)
    @ffmpeg = data["ffmpeg"].to_s
    @ffprobe = data["ffprobe"].to_s
    @frame_delay_ms = data["frameDelayMs"].to_i
  end
end

# "toolbar": the floating bar's place, text and animation.
class ToolbarSettings
  attr_reader :bottom_gap, :timer_text_size, :countdown_text_size, :hover_fade_speed, :pulse_speed,
              :pressed_icon_scale, :hide_wait_ms

  def initialize(data)
    @bottom_gap = data["bottomGap"].to_i
    @timer_text_size = data["timerTextSize"].to_i
    @countdown_text_size = data["countdownTextSize"].to_i
    @hover_fade_speed = data["hoverFadeSpeed"].to_f
    @pulse_speed = data["pulseSpeed"].to_f
    @pressed_icon_scale = data["pressedIconScale"].to_f
    @hide_wait_ms = data["hideWaitMs"].to_i
  end
end

# "recording": the take (frame rate, folder, the project folders'
# extension, countdown, encoding, the key that stops it) and the marks of
# a picked area.
class RecordingSettings
  attr_reader :fps, :folder, :project_extension, :countdown, :codec, :bitrate, :capture_start_timeout, :stop_shortcut,
              :smallest_area, :picker_shade, :area_shade, :outline_color, :halo_color

  def initialize(data)
    @fps = data["fps"].to_i
    @folder = File.expand_path(data["folder"].to_s)
    @project_extension = data["projectExtension"].to_s
    @countdown = data["countdown"].to_i
    @codec = data["codec"].to_s
    @bitrate = data["bitrate"].to_s
    @capture_start_timeout = data["captureStartTimeout"].to_f
    @stop_shortcut = data["stopShortcut"].to_s
    area = data["area"]
    @smallest_area = area["smallest"].to_i
    @picker_shade = Color.parse(area["pickerShade"].to_s)
    @area_shade = Color.parse(area["shade"].to_s)
    @outline_color = Color.parse(area["outline"].to_s)
    @halo_color = Color.parse(area["halo"].to_s)
  end
end

# "export": the folder the Save panel suggests, and the finished video's
# size and encoding.
class ExportSettings
  attr_reader :folder, :width, :height, :codec, :bitrate

  def initialize(data)
    @folder = File.expand_path(data["folder"].to_s)
    @width = data["width"].to_i
    @height = data["height"].to_i
    @codec = data["codec"].to_s
    @bitrate = data["bitrate"].to_s
  end
end

# "editor": the timeline's rules, how close the pointer must be to grab
# something, how often the panel refreshes, the scrub frames and the
# keyboard shortcuts. zoom_amount is a new zoom's, from the project.
class EditorSettings
  attr_reader :frame_delay_ms, :shortest_clip, :new_zoom_length, :zoom_step, :smallest_zoom, :largest_zoom,
              :edge_grab, :playhead_grab, :history_limit, :clock_refresh, :thumbnail_refresh, :export_slice,
              :progress_step, :time_left_after, :catch_up, :scrub_width, :scrub_height, :thumbnail_width, :thumbnail_fps,
              :tile_width, :shortcuts, :zoom_amount

  def initialize(data, zoom_amount)
    @frame_delay_ms = data["frameDelayMs"].to_i
    @shortest_clip = data["shortestClip"].to_f
    @new_zoom_length = data["newZoomLength"].to_f
    @zoom_step = data["zoomStep"].to_f
    @smallest_zoom = data["zoomRange"][0].to_f
    @largest_zoom = data["zoomRange"][1].to_f
    @edge_grab = data["edgeGrab"].to_i
    @playhead_grab = data["playheadGrab"].to_i
    @history_limit = data["historyLimit"].to_i
    @clock_refresh = data["clockRefresh"].to_f
    @thumbnail_refresh = data["thumbnailRefresh"].to_f
    @export_slice = data["exportSlice"].to_f
    @progress_step = data["progressStep"].to_f
    @time_left_after = data["timeLeftAfter"].to_f
    @catch_up = data["catchUp"].to_f
    @scrub_width = data["scrubPreview"][0].to_i
    @scrub_height = data["scrubPreview"][1].to_i
    @thumbnail_width = data["thumbnails"]["width"].to_i
    @thumbnail_fps = data["thumbnails"]["fps"].to_i
    @tile_width = data["thumbnails"]["tileWidth"].to_i
    @shortcuts = Shortcuts.new(data["shortcuts"])
    @zoom_amount = zoom_amount
  end
end

# "render": how frames are made.
class RenderSettings
  attr_reader :halve_below, :cursor_steps_per_frame

  def initialize(data)
    @halve_below = data["halveBelow"].to_f
    @cursor_steps_per_frame = data["cursorStepsPerFrame"].to_i
  end
end

require "minitest/autorun"

# The tests run the pure Ruby classes under CRuby. The files that bind
# native libraries (ffi_func) only compile with Spinel, so they stay out.
PURE_FILES = %w[
  settings project/span project/zoom_plan project/timeline project/history project/track project/project_config project/project_folder
  recording/recording_meta render/canvas render/cursor render/camera render/compositor render/cursor_sprite
  recording/area_outline recording/recording_session ui/theme ui/shortcuts ui/button platform/macos/system_cursor ui/toolbar ui/timeline_view
].freeze
PURE_FILES.each { |name| require_relative "../spinel_studio/#{name}" }

DEFAULTS = JSON.parse(File.read(File.expand_path("../config/application.json", __dir__)))

SETTINGS = Settings.new(DEFAULTS)

def background
  Background.new(DEFAULTS["project"]["background"])
end

def zoom_style
  ZoomStyle.new(DEFAULTS["project"]["zoom"])
end

def zoom_plan(segments)
  ZoomPlan.new(segments, zoom_style.ramp)
end

def cursor_style
  CursorStyle.new(DEFAULTS["project"]["cursor"])
end

def camera_style
  CameraStyle.new(DEFAULTS["project"]["camera"])
end

# A track from [time, x, y, pressed] samples.
def track_of(samples)
  Track.new(samples.map { |time, x, y, pressed| "#{time} #{x} #{y} #{pressed ? 1 : 0}" })
end

# Stands in for Typeface: fixed-size glyphs, remembers what it drew.
class FakeTypeface
  attr_reader :drawn

  def initialize
    @drawn = []
  end

  def measure(text, _large)
    [text.size * 8, 16]
  end

  def draw(_canvas, text, _x, _y, _large, _color)
    @drawn << text
  end
end

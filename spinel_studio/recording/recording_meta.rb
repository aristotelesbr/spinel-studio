require "json"

# What was recorded, in recording-meta.json beside the video (Cap keeps
# the same file): the frame rate, the display's pixel density and the
# picked area in screen pixels (nil for the whole display).
class RecordingMeta
  FILE = "recording-meta.json"

  attr_reader :fps, :pixel_density, :area

  def initialize(fps, pixel_density, area)
    @fps = fps
    @pixel_density = pixel_density
    @area = area
  end

  # Takes recorded before this file existed: 30 fps, the old area.txt.
  OLDER_FPS = 30

  def self.load(dir)
    return older(dir) unless File.exist?("#{dir}/#{FILE}")
    data = JSON.parse(File.read("#{dir}/#{FILE}"))
    area = data["area"]
    RecordingMeta.new(data["fps"].to_i, data["pixelDensity"].to_i,
                      area ? [area["x"].to_i, area["y"].to_i, area["width"].to_i, area["height"].to_i] : [])
  end

  def self.older(dir)
    area_file = "#{dir}/area.txt"
    area = File.exist?(area_file) ? File.read(area_file).split(" ").map(&:to_i) : []
    RecordingMeta.new(OLDER_FPS, 2, area)
  end

  def save(dir)
    area = @area.empty? ? nil : { "x" => @area[0], "y" => @area[1], "width" => @area[2], "height" => @area[3] }
    File.write("#{dir}/#{FILE}", JSON.pretty_generate({ "fps" => @fps, "pixelDensity" => @pixel_density, "area" => area }) + "\n")
  end
end

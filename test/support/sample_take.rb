# Writes a synthetic take into ARGV[0]: a mouse log that crosses the
# screen with two clicks, its recording-meta.json, and a project whose
# timeline keeps two clips (1 s removed between them) and two zooms.
# The screen video is made by script/render_check with ffmpeg.
require "json"
dir = ARGV[0]
Dir.mkdir(dir) unless Dir.exist?(dir)
lines = (0...(6 * 120)).map do |step|
  time = step / 120.0
  pressed = [1.5, 4.0].any? { |click| time >= click && time < click + 0.05 }
  "#{time.round(4)} #{(400 + time * 380).round} #{(500 + time * 120).round} #{pressed ? 1 : 0}"
end
File.write("#{dir}/mouse.log", (lines + ["end 6.0"]).join("\n") + "\n")
File.write("#{dir}/recording-meta.json", JSON.generate({ "fps" => 30, "pixelDensity" => 2, "area" => nil }))
defaults = JSON.parse(File.read(File.expand_path("../../config/application.json", __dir__)))["project"]
File.write("#{dir}/project-config.json", JSON.pretty_generate({
  "background" => defaults["background"], "cursor" => defaults["cursor"],
  "timeline" => { "segments" => [{ "start" => 0.0, "end" => 2.5 }, { "start" => 3.5, "end" => 6.0 }],
                  "zoomSegments" => [{ "start" => 1.0, "end" => 2.4, "amount" => 2.0 }, { "start" => 3.6, "end" => 5.8, "amount" => 1.6 }] }
}))

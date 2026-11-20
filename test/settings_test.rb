require_relative "test_helper"
require "tmpdir"

class SettingsTest < Minitest::Test
  def test_layers_each_file_that_exists_over_the_defaults_in_order
    Dir.mktmpdir do |dir|
      File.write("#{dir}/application.json", JSON.generate("export" => { "codec" => "a", "bitrate" => "16M" }, "app" => { "ffmpeg" => "x" }))
      File.write("#{dir}/linux.json", JSON.generate("export" => { "codec" => "b" }, "app" => { "ffmpeg" => "y" }))
      File.write("#{dir}/settings.json", JSON.generate("app" => { "ffmpeg" => "z" }))

      data = Settings.layered("#{dir}/application.json", ["#{dir}/linux.json", "#{dir}/missing.json", "#{dir}/settings.json"])

      assert_equal({ "codec" => "b", "bitrate" => "16M" }, data["export"])
      assert_equal "z", data["app"]["ffmpeg"]
    end
  end

  def test_the_defaults_alone_when_no_other_file_exists
    Dir.mktmpdir do |dir|
      File.write("#{dir}/application.json", JSON.generate("app" => { "ffmpeg" => "x" }))

      assert_equal({ "app" => { "ffmpeg" => "x" } }, Settings.layered("#{dir}/application.json", ["#{dir}/none.json"]))
    end
  end
end

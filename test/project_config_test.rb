require_relative "test_helper"
require "tmpdir"

class ProjectConfigTest < Minitest::Test
  def test_a_new_project_starts_from_the_defaults
    project = ProjectConfig.fresh(DEFAULTS["project"], 8.0, [2.0])
    assert_equal 90, project.background.padding
    assert_equal 0x3B2A8F, project.background.top_color
    assert_in_delta 80.0, project.cursor.size
    assert_in_delta 2.0, project.timeline.zooms[0].amount
  end

  def test_a_project_survives_a_round_trip_through_its_file
    Dir.mktmpdir do |dir|
      project = ProjectConfig.fresh(DEFAULTS["project"], 8.0, [2.0])
      project.timeline.split(5.0, 0.3)
      project.save(dir)
      again = ProjectConfig.open(dir, DEFAULTS["project"], 8.0, [])
      assert_equal [[0.0, 5.0], [5.0, 8.0]], again.timeline.clips.map { |clip| [clip.start, clip.finish] }
      assert_equal project.timeline.zooms.map(&:start), again.timeline.zooms.map(&:start)
      assert_equal "#3B2A8F", again.background.to_h["gradient"][0]
    end
  end

  def test_a_take_saved_before_a_setting_existed_takes_the_default
    Dir.mktmpdir do |dir|
      data = ProjectConfig.fresh(DEFAULTS["project"], 8.0, [2.0]).to_h
      data.delete("camera")
      data["cursor"].delete("clickGrip")
      File.write("#{dir}/#{ProjectConfig::FILE}", JSON.generate(data))
      project = ProjectConfig.open(dir, DEFAULTS["project"], 8.0, [])
      assert_in_delta 5.0, project.camera.follow
      assert_in_delta 4.0, project.cursor.click_grip
    end
  end

  def test_the_file_uses_the_names_cap_uses
    data = ProjectConfig.fresh(DEFAULTS["project"], 8.0, [2.0]).to_h
    assert data["timeline"].key?("segments")
    assert data["timeline"].key?("zoomSegments")
    assert data["timeline"]["zoomSegments"][0].key?("amount")
  end
end

class RecordingMetaTest < Minitest::Test
  def test_meta_survives_a_round_trip
    Dir.mktmpdir do |dir|
      RecordingMeta.new(30, 2, [10, 20, 300, 200]).save(dir)
      meta = RecordingMeta.load(dir)
      assert_equal [30, 2, [10, 20, 300, 200]], [meta.fps, meta.pixel_density, meta.area]
    end
  end

  def test_an_older_take_reads_its_area_file
    Dir.mktmpdir do |dir|
      File.write("#{dir}/area.txt", "1 2 3 4\n")
      assert_equal [1, 2, 3, 4], RecordingMeta.load(dir).area
    end
  end
end

class SettingsTest < Minitest::Test
  def test_user_settings_override_only_what_they_name
    merged = Settings.merged(DEFAULTS, { "recording" => { "fps" => 60 } })
    settings = Settings.new(merged)
    assert_equal 60, settings.recording.fps
    assert_equal 1920, settings.export.width
    assert settings.recording.folder.end_with?("Movies/Spinel Studio")
  end

  def test_editor_rules_come_from_the_file
    assert_in_delta 0.3, SETTINGS.editor.shortest_clip
    assert_in_delta 1.25, SETTINGS.editor.smallest_zoom
    assert_in_delta 3.0, SETTINGS.editor.largest_zoom
    assert_equal 480, SETTINGS.editor.thumbnail_width
    assert_equal 3, SETTINGS.recording.countdown
  end

  def test_colors_read_as_argb
    assert_equal 0xFF111114, SETTINGS.theme.window
    assert_equal 0x4D000000, SETTINGS.recording.area_shade
    assert_equal 0xF21E1E24, SETTINGS.theme.surface
  end

  def test_the_theme_names_its_fonts
    assert_equal "Semibold", SETTINGS.theme.font.weight
    assert SETTINGS.theme.dialog_font.path.end_with?("SFNS.ttf")
  end
end

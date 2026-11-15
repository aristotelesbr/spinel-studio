require_relative "test_helper"
require "tmpdir"
require "fileutils"

class ProjectFolderTest < Minitest::Test
  def take(dir)
    FileUtils.mkdir_p(dir)
    File.write("#{dir}/screen.mov", "")
    File.write("#{dir}/project-config.json", "{}")
    dir
  end

  def test_a_project_folder_opens_as_itself
    Dir.mktmpdir do |root|
      project = take("#{root}/2026-11-15 14.00.00.spinelstudio")
      assert_equal project, ProjectFolder.resolve(project)
    end
  end

  def test_a_file_inside_an_older_take_opens_its_folder
    Dir.mktmpdir do |root|
      older = take("#{root}/2026-11-14 21.33.59")
      assert_equal older, ProjectFolder.resolve("#{older}/project-config.json")
    end
  end

  def test_anything_else_is_not_a_project
    Dir.mktmpdir do |root|
      assert_equal "", ProjectFolder.resolve(root)
      assert_equal "", ProjectFolder.resolve("#{root}/missing.spinelstudio")
    end
  end

  def test_the_name_leaves_out_the_extension
    assert_equal "2026-11-15 14.00.00", ProjectFolder.name("/takes/2026-11-15 14.00.00.spinelstudio", "spinelstudio")
    assert_equal "2026-11-14 21.33.59", ProjectFolder.name("/takes/2026-11-14 21.33.59", "spinelstudio")
  end
end

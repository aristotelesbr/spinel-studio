# Where a project lives. A take is a folder (screen.mov, mouse.log,
# recording-meta.json, project-config.json); new ones are named
# NAME.spinelstudio, which Finder shows as one document, as Cap keeps its
# recordings in .cap folders. Takes from before the extension are plain
# folders and open the same way.
module ProjectFolder
  SCREEN = "screen.mov"

  # The project folder for a path the user opened: the folder itself, or
  # the folder of a file picked inside an older take. "" when it is not a
  # take.
  def self.resolve(path)
    return path if take?(path)
    folder = File.dirname(path)
    take?(folder) ? folder : ""
  end

  def self.take?(path)
    File.directory?(path) && File.exist?("#{path}/#{SCREEN}")
  end

  # The project's name as shown: the folder's name without its extension.
  def self.name(path, extension)
    File.basename(path, ".#{extension}")
  end
end

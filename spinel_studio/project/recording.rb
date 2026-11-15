# A take opened for editing or export, loaded once: the video's size and
# length, what was recorded, the mouse log and the project's edits.
class Recording
  attr_reader :dir, :screen, :frame_width, :frame_height, :duration, :fps, :area, :track, :project

  def initialize(dir, settings)
    @dir = dir
    @screen = "#{dir}/screen.mov"
    @frame_width, @frame_height = FFmpeg.frame_size(@screen)
    @duration = FFmpeg.duration(@screen)
    meta = RecordingMeta.load(dir)
    @fps = meta.fps
    @area = meta.area.empty? ? [0, 0, @frame_width, @frame_height] : meta.area
    @track = Track.load("#{dir}/mouse.log")
    @project = ProjectConfig.open(dir, settings.project_defaults, @duration, @track.clicks)
    @project.save(dir)
  end

  def timeline
    @project.timeline
  end

  def save
    @project.save(@dir)
  end
end

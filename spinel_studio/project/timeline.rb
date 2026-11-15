# The timeline of a project, as Cap models it: the clips of the
# recording that stay in the video (cutting splits a clip and removes a
# piece) and the zoom segments. Times are seconds of recording time.
class Timeline
  attr_reader :clips, :zooms

  def initialize(clips, zooms)
    @clips = clips.sort_by(&:start)
    @zooms = zooms.sort_by(&:start)
  end

  # The whole recording as one clip, and a zoom per burst of clicks.
  def self.fresh(duration, clicks, zoom_style)
    Timeline.new([Span.new(0.0, duration)], ZoomPlan.segments_for_clicks(clicks, zoom_style))
  end

  def kept?(time)
    @clips.any? { |clip| clip.covers?(time) }
  end

  # Where the video goes on after time: time itself inside a clip, the
  # start of the next clip after a gap, or nil past the last clip.
  def resume_at(time)
    return time if kept?(time)
    following = @clips.find { |clip| clip.start >= time }
    following ? following.start : nil
  end

  def clip_at(time)
    @clips.find { |clip| clip.covers?(time) }
  end

  # Splits the clip under time in two; the new right-hand clip, or nil
  # when either piece would be shorter than shortest seconds.
  def split(time, shortest)
    clip = clip_at(time)
    return nil unless clip && time - clip.start >= shortest && clip.finish - time >= shortest
    right = Span.new(time, clip.finish)
    clip.finish = time
    @clips << right
    @clips.sort_by!(&:start)
    right
  end

  def remove(span)
    @clips.delete_if { |clip| clip.equal?(span) }
    @zooms.delete_if { |zoom| zoom.equal?(span) }
  end

  def add_zoom(zoom)
    @zooms << zoom
    @zooms.sort_by!(&:start)
  end

  # Puts in the clips and zooms of an earlier state (undo, redo).
  def replace(clips, zooms)
    @clips = clips.sort_by(&:start)
    @zooms = zooms.sort_by(&:start)
  end

  def sort
    @clips.sort_by!(&:start)
    @zooms.sort_by!(&:start)
  end

  # Drops what starts after the end and trims what runs past it.
  def fit(duration)
    [@clips, @zooms].each do |spans|
      spans.select! { |span| span.start < duration }
      spans.each { |span| span.finish = [span.finish, duration].min }
    end
  end

  # Seconds of video the clips make.
  def length
    @clips.sum(&:length)
  end
end

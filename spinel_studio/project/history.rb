# Undo and redo for the timeline, as Cap's editor does it: before an edit
# the timeline is copied; undo puts the copy back and keeps the current
# state for redo. A gesture that changed nothing leaves no step.
class History
  # limit: how many steps undo keeps.
  def initialize(timeline, limit)
    @timeline = timeline
    @limit = limit
    @undo = []
    @redo = []
    @before = nil
  end

  # Call before something that may change the timeline.
  def record
    @before = TimelineCopy.new(@timeline)
  end

  # Call after it; keeps a step only when the timeline changed.
  def commit
    before = @before
    @before = nil
    return unless before && !before.same?(TimelineCopy.new(@timeline))
    @undo << before
    @undo.shift if @undo.size > @limit
    @redo.clear
  end

  def undo
    step(@undo, @redo)
  end

  def redo
    step(@redo, @undo)
  end

  private

  def step(from, to)
    return false if from.empty?
    to << TimelineCopy.new(@timeline)
    from.pop.restore(@timeline)
    true
  end
end

# The clips and zooms of a timeline at one moment, as plain numbers.
class TimelineCopy
  attr_reader :clips, :zooms

  def initialize(timeline)
    @clips = timeline.clips.map { |clip| [clip.start, clip.finish] }.flatten
    @zooms = timeline.zooms.map { |zoom| [zoom.start, zoom.finish, zoom.amount] }.flatten
  end

  def same?(other)
    @clips == other.clips && @zooms == other.zooms
  end

  def restore(timeline)
    clips = (0...@clips.size / 2).map { |index| Span.new(@clips[index * 2], @clips[index * 2 + 1]) }
    zooms = (0...@zooms.size / 3).map { |index| Span.new(@zooms[index * 3], @zooms[index * 3 + 1], @zooms[index * 3 + 2]) }
    timeline.replace(clips, zooms)
  end
end

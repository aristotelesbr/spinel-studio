# How far the video is zoomed at each moment, from the zoom segments.
# A recording starts with one segment per burst of clicks.
# Each segment eases in and out over ramp seconds.
class ZoomPlan
  attr_reader :segments

  def initialize(segments, ramp)
    @segments = segments.sort_by(&:start)
    @ramp = ramp
  end

  # One segment per burst of clicks, placed as the ZoomStyle says.
  def self.segments_for_clicks(clicks, style)
    segments = []
    clicks.sort.each do |click|
      last = segments.last
      if last && click - style.lead <= last.finish + style.join_within
        last.finish = click + style.hold
      else
        segments << Span.new([click - style.lead, 0.0].max, click + style.hold, style.amount)
      end
    end
    segments
  end

  def segment_at(time)
    @segments.find { |segment| segment.covers?(time) }
  end

  def scale_at(time)
    segment = segment_at(time)
    return 1.0 unless segment
    1.0 + (segment.amount - 1.0) * segment.strength_at(time, @ramp)
  end
end

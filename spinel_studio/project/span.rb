# A stretch of the recording, in seconds of recording time: a clip of the
# timeline, or a zoom segment with its amount. One class for both keeps
# every value the editor touches a plain Float for Spinel.
#
# As a zoom it eases in over its first ramp seconds, holds, and eases
# out over its last ramp seconds.
class Span
  attr_accessor :start, :finish, :amount

  def initialize(start, finish, amount = 1.0)
    @start = start
    @finish = finish
    @amount = amount
  end

  def covers?(time)
    time >= @start && time < @finish
  end

  def length
    @finish - @start
  end

  # How zoomed in the segment is at time: 0 outside, 1 when fully in.
  def strength_at(time, ramp)
    return 0.0 unless covers?(time)
    ramp = [ramp, length / 2].min
    Span.ease([(time - @start) / ramp, (@finish - time) / ramp, 1.0].min)
  end

  # Smooth in and out (smoothstep): 0 -> 0, 1 -> 1, flat at both ends.
  def self.ease(share)
    share = share.clamp(0.0, 1.0)
    share * share * (3 - 2 * share)
  end
end

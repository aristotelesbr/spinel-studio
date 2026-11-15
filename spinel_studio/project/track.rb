# The mouse log written during a recording.
#
# Lines are "time x y pressed" (seconds since the first frame, screen
# pixels, left button 0 or 1), then "end time" when the capture stopped.
class Track
  attr_reader :clicks

  def initialize(lines)
    @times = []
    @xs = []
    @ys = []
    @clicks = []
    was_pressed = false
    lines.each do |line|
      fields = line.split(" ")
      next if fields.empty? || fields[0] == "end"
      time = fields[0].to_f
      pressed = fields[3] == "1"
      @times << time
      @xs << fields[1].to_f
      @ys << fields[2].to_f
      @clicks << time if pressed && !was_pressed
      was_pressed = pressed
    end
  end

  def self.load(path)
    Track.new(File.readlines(path))
  end

  # Cursor position at time, interpolated between the samples around it.
  def x_at(time)
    interpolate(@xs, time)
  end

  def y_at(time)
    interpolate(@ys, time)
  end

  # Seconds since the latest click at or before time (infinite if none).
  def since_click(time)
    latest = @clicks.select { |click| click <= time }.max
    latest ? time - latest : Float::INFINITY
  end

  private

  def interpolate(values, time)
    return 0.0 if values.empty?
    after = @times.bsearch_index { |sample| sample > time } || @times.size
    return values[0] if after == 0
    return values[after - 1] if after == @times.size
    before = after - 1
    span = @times[after] - @times[before]
    share = span > 0 ? (time - @times[before]) / span : 0.0
    values[before] + (values[after] - values[before]) * share
  end
end

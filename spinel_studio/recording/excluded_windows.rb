# The window numbers to leave out of a capture, as the C array that
# studio_capture_start takes.
class ExcludedWindows
  attr_reader :list, :count

  def initialize(numbers)
    @count = numbers.size
    @list = IO::Buffer.new([numbers.size, 1].max * 8)
    numbers.each_with_index { |number, index| @list.set_value(:s64, index * 8, number) }
  end
end

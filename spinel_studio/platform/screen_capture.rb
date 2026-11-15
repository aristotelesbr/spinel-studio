# Screen frames from ScreenCaptureKit, the API that can leave a window
# out of a capture: the toolbar stays on screen but not in the video.
# The functions live in native/capture.m, which script/build compiles into
# build/libspinel_studio_native.a.
module ScreenCapture
  ffi_lib "spinel_studio_native"
  ffi_cflags "-L" + File.expand_path("../../build", __dir__)
  ffi_cflags "-framework ScreenCaptureKit -framework CoreMedia -framework CoreVideo -framework AppKit"

  ffi_func :studio_window_number, [:ptr], :long
  ffi_func :studio_window_ignore_mouse, [:ptr], :void
  ffi_func :studio_capture_start, [:ptr, :long, :long, :long, :int], :int
  ffi_func :studio_capture_frame, [:ptr], :long
  ffi_func :studio_capture_stop, [], :void
  ffi_func :studio_screenshot, [:ptr, :long, :long], :int
end

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

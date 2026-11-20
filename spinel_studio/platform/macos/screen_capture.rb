# Screen frames from ScreenCaptureKit, the API that can leave a window
# out of a capture: the toolbar stays on screen but not in the video.
# The functions live in native/capture.m, which script/build compiles into
# build/libspinel_studio_native.a.
module ScreenCapture
  ffi_lib "spinel_studio_native"
  ffi_cflags "-L" + File.expand_path("../../../build", __dir__)
  ffi_cflags "-framework ScreenCaptureKit -framework CoreMedia -framework CoreVideo -framework AppKit"

  ffi_func :studio_window_number, [:ptr], :long
  ffi_func :studio_window_ignore_mouse, [:ptr], :void
  ffi_func :studio_capture_start, [:ptr, :long, :long, :long, :int], :int
  ffi_func :studio_capture_frame, [:ptr], :long
  ffi_func :studio_capture_stop, [], :void
  ffi_func :studio_screenshot, [:ptr, :long, :long], :int

  # The macOS window number of an SDL window, to leave it out of a capture.
  def self.window_number(window)
    ScreenCapture.studio_window_number(SDL.cocoa_window(window))
  end

  # Clicks go through the SDL window to whatever is below.
  def self.ignore_mouse(window)
    ScreenCapture.studio_window_ignore_mouse(SDL.cocoa_window(window))
  end
end

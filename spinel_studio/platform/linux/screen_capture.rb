# Screen frames from X11, with the same functions as the macOS side.
# They live in native/capture_x11.c, which script/build compiles into
# build/libspinel_studio_native.a. X11 cannot leave a window out of a
# capture, so the excluded windows are ignored.
module ScreenCapture
  ffi_lib "spinel_studio_native"
  ffi_cflags "-L" + File.expand_path("../../../build", __dir__)
  ffi_lib "X11"
  ffi_lib "Xfixes"

  ffi_func :studio_window_ignore_mouse, [:long], :void
  ffi_func :studio_capture_start, [:ptr, :long, :long, :long, :int], :int
  ffi_func :studio_capture_frame, [:ptr], :long
  ffi_func :studio_capture_stop, [], :void
  ffi_func :studio_screenshot, [:ptr, :long, :long], :int
  ffi_func :studio_key_down, [:long], :bool
  ffi_func :studio_pointer, [:ptr, :ptr], :bool

  # The X11 window of an SDL window.
  def self.window_number(window)
    SDL.SDL_GetNumberProperty(SDL.SDL_GetWindowProperties(window), "SDL.window.x11.window", 0)
  end

  # Clicks go through the SDL window to whatever is below.
  def self.ignore_mouse(window)
    ScreenCapture.studio_window_ignore_mouse(window_number(window))
  end
end

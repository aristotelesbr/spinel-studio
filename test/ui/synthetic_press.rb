# Posts one mouse event at (x, y) points: ARGV[2] is "move", "down",
# "drag" (moved with the button held) or "up". Lets a test hold the
# button down while it looks at the screen.
module Presses
  ffi_cflags "-framework ApplicationServices"
  ffi_func :CGEventCreateMouseEvent, [:ptr, :uint32, :double, :double, :uint32], :ptr
  ffi_func :CGEventPost, [:uint32, :ptr], :void
  ffi_func :CFRelease, [:ptr], :void
end
TYPES = { "down" => 1, "up" => 2, "move" => 5, "drag" => 6 }.freeze
event = Presses.CGEventCreateMouseEvent(nil, TYPES[ARGV[2]], ARGV[0].to_f, ARGV[1].to_f, 0)
Presses.CGEventPost(0, event)
Presses.CFRelease(event)

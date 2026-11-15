# Posts a mouse click at (x, y) points: ARGV[0], ARGV[1]. CGPoint is two
# doubles, which arm64 passes exactly like two double arguments.
module Clicks
  ffi_cflags "-framework ApplicationServices"
  ffi_func :CGEventCreateMouseEvent, [:ptr, :uint32, :double, :double, :uint32], :ptr
  ffi_func :CGEventPost, [:uint32, :ptr], :void
  ffi_func :CFRelease, [:ptr], :void
end
MOVED = 5
DOWN = 1
UP = 2
x = ARGV[0].to_f
y = ARGV[1].to_f
[MOVED, DOWN, UP].each do |type|
  event = Clicks.CGEventCreateMouseEvent(nil, type, x, y, 0)
  Clicks.CGEventPost(0, event)
  Clicks.CFRelease(event)
  sleep 0.15
end

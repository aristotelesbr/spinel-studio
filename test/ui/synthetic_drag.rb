# Posts a left-button drag from (ARGV[0], ARGV[1]) to (ARGV[2], ARGV[3]).
module Clicks
  ffi_cflags "-framework ApplicationServices"
  ffi_func :CGEventCreateMouseEvent, [:ptr, :uint32, :double, :double, :uint32], :ptr
  ffi_func :CGEventPost, [:uint32, :ptr], :void
  ffi_func :CFRelease, [:ptr], :void
end
def post(type, x, y)
  event = Clicks.CGEventCreateMouseEvent(nil, type, x, y, 0)
  Clicks.CGEventPost(0, event)
  Clicks.CFRelease(event)
end
from_x = ARGV[0].to_f
from_y = ARGV[1].to_f
to_x = ARGV[2].to_f
to_y = ARGV[3].to_f
post(5, from_x, from_y)
sleep 0.1
post(1, from_x, from_y)
20.times do |step|
  share = (step + 1) / 20.0
  post(6, from_x + (to_x - from_x) * share, from_y + (to_y - from_y) * share)
  sleep 0.03
end
post(2, to_x, to_y)

# The cursor and the keyboard, read from CoreGraphics and SDL. Positions
# are in screen pixels (points times the display's pixel density), the
# space of the captured frames.
module Mouse
  ffi_cflags "-framework ApplicationServices"

  ffi_func :CGMainDisplayID, [], :uint32
  ffi_func :CGDisplayCopyDisplayMode, [:uint32], :ptr
  ffi_func :CGDisplayModeGetPixelWidth, [:ptr], :size_t
  ffi_func :CGDisplayModeGetWidth, [:ptr], :size_t
  ffi_func :CGDisplayModeRelease, [:ptr], :void
  ffi_func :CGEventSourceButtonState, [:int, :uint32], :bool
  ffi_func :CGEventSourceKeyState, [:int, :uint16], :bool

  COMBINED_SESSION_STATE = 0
  LEFT_BUTTON = 0

  # macOS key codes (ANSI layout) by the names a shortcut uses; a
  # modifier is its left and right key.
  KEY_CODES = {
    "Ctrl" => [0x3B, 0x3E], "Option" => [0x3A, 0x3D], "Shift" => [0x38, 0x3C], "Cmd" => [0x37, 0x36],
    "A" => [0x00], "S" => [0x01], "D" => [0x02], "F" => [0x03], "H" => [0x04], "G" => [0x05], "Z" => [0x06],
    "X" => [0x07], "C" => [0x08], "V" => [0x09], "B" => [0x0B], "Q" => [0x0C], "W" => [0x0D], "E" => [0x0E],
    "R" => [0x0F], "Y" => [0x10], "T" => [0x11], "O" => [0x1F], "U" => [0x20], "I" => [0x22], "P" => [0x23],
    "L" => [0x25], "J" => [0x26], "K" => [0x28], "N" => [0x2D], "M" => [0x2E],
    "1" => [0x12], "2" => [0x13], "3" => [0x14], "4" => [0x15], "5" => [0x17], "6" => [0x16], "7" => [0x1A],
    "8" => [0x1C], "9" => [0x19], "0" => [0x1D], "Escape" => [0x35], "Space" => [0x31]
  }.freeze

  def self.pixel_density
    mode = Mouse.CGDisplayCopyDisplayMode(Mouse.CGMainDisplayID)
    density = Mouse.CGDisplayModeGetPixelWidth(mode) / Mouse.CGDisplayModeGetWidth(mode)
    Mouse.CGDisplayModeRelease(mode)
    density
  end

  # [x, y] in screen pixels.
  def self.position(density)
    points = SDL.global_mouse
    [points[0] * density, points[1] * density]
  end

  def self.pressed?
    Mouse.CGEventSourceButtonState(COMBINED_SESSION_STATE, LEFT_BUTTON)
  end

  def self.key_down?(key_code)
    Mouse.CGEventSourceKeyState(COMBINED_SESSION_STATE, key_code)
  end

  # A shortcut like "Ctrl+Option+S" as the key codes of each part.
  def self.key_groups(shortcut)
    shortcut.split("+").map { |name| KEY_CODES.fetch(name, []) }
  end

  # Whether every part of the shortcut is held, anywhere on screen.
  def self.held?(key_groups)
    key_groups.all? { |codes| codes.any? { |code| key_down?(code) } }
  end
end

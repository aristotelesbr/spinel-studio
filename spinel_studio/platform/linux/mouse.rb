# The cursor and the keyboard, read from X11. Positions are in
# screen pixels, the space of the captured frames.
module Mouse
  # X11 keysyms by the names a shortcut uses; a modifier is its left and
  # right key. Option is Alt and Cmd is Super.
  KEY_CODES = {
    "Ctrl" => [0xFFE3, 0xFFE4], "Option" => [0xFFE9, 0xFFEA], "Shift" => [0xFFE1, 0xFFE2], "Cmd" => [0xFFEB, 0xFFEC],
    "A" => [0x61], "B" => [0x62], "C" => [0x63], "D" => [0x64], "E" => [0x65], "F" => [0x66], "G" => [0x67],
    "H" => [0x68], "I" => [0x69], "J" => [0x6A], "K" => [0x6B], "L" => [0x6C], "M" => [0x6D], "N" => [0x6E],
    "O" => [0x6F], "P" => [0x70], "Q" => [0x71], "R" => [0x72], "S" => [0x73], "T" => [0x74], "U" => [0x75],
    "V" => [0x76], "W" => [0x77], "X" => [0x78], "Y" => [0x79], "Z" => [0x7A],
    "1" => [0x31], "2" => [0x32], "3" => [0x33], "4" => [0x34], "5" => [0x35], "6" => [0x36], "7" => [0x37],
    "8" => [0x38], "9" => [0x39], "0" => [0x30], "Escape" => [0xFF1B], "Space" => [0x20]
  }.freeze

  # X11 screens are measured in pixels already.
  def self.pixel_density
    1
  end

  # [x, y] in screen pixels. X11 is asked directly: SDL only follows the
  # pointer while its events are read, which `record` does not do.
  def self.position(density)
    x = IO::Buffer.new(4)
    y = IO::Buffer.new(4)
    ScreenCapture.studio_pointer(x, y)
    [x.get_value(:s32, 0) * density, y.get_value(:s32, 0) * density]
  end

  def self.pressed?
    ScreenCapture.studio_pointer(IO::Buffer.new(4), IO::Buffer.new(4))
  end

  def self.key_down?(key_code)
    ScreenCapture.studio_key_down(key_code)
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

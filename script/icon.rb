# Paints the app icon (1024x1024, raw premultiplied BGRA to ARGV[0]) with
# the toolbar's canvas: a violet tile, a framed window on it, and a ruby
# gem for the language the app is written in.
require_relative "../spinel_studio/render/canvas"
require_relative "../spinel_studio/render/ruby_gem"

c = Canvas.new(1024, 1024)
c.clear(0)
# macOS icon grid: 824 px tile, 100 px margin
c.soft_shadow(100, 112, 824, 824, 185, 24, 0x55000000)
c.fill_rounded(100, 100, 824, 824, 185, 0xFF5B3FD9)
c.fill_rounded(100, 100, 824, 440, 185, 0x337C6CF6)
c.soft_shadow(230, 290, 564, 400, 40, 40, 0x66000000)
c.fill_rounded(230, 270, 564, 400, 40, 0xFFF5F5FA)
c.fill_rounded(230, 270, 564, 56, 40, 0xFFE4E4EE)
c.fill_rounded(230, 300, 564, 26, 0, 0xFFE4E4EE)
[268, 302, 336].each { |x| c.circle(x, 298, 11, 0xFFB9B9C8) }
c.soft_shadow(640, 640, 170, 150, 40, 30, 0x55000000)
RubyGem.draw(c, 725, 690, 190)

f = File.open(ARGV[0], "wb")
c.pixels.write(f, c.pixels.size)
f.close

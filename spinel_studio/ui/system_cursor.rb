# A macOS cursor taken from the system's own files: each cursor is a
# folder with cursor.pdf (32 points square) and info.plist (its hot spot
# and shadow), under the folders the app settings list (the newest
# system's first). The PDF is drawn at the screen's scale, so the
# pointer looks exactly like the system's, and SDL shows it.
class SystemCursor
  POINTS = 32

  # An SDL cursor of the named system cursor ("openhand", "closedhand"),
  # or nil when no folder has it.
  def self.create(name, folders, scale)
    folder = folders.find { |each| File.exist?("#{each}/#{name}/cursor.pdf") }
    return nil unless folder
    info = CursorInfo.new(File.read("#{folder}/#{name}/info.plist"))
    pdf = "#{folder}/#{name}/cursor.pdf"
    normal = SystemCursor.new(pdf, info, 1.0)
    sharp = SystemCursor.new(pdf, info, scale)
    surface = normal.surface
    sharp_surface = sharp.surface
    SDL.SDL_AddSurfaceAlternateImage(surface, sharp_surface)
    cursor = SDL.SDL_CreateColorCursor(surface, info.hot_x, info.hot_y)
    SDL.SDL_DestroySurface(sharp_surface)
    SDL.SDL_DestroySurface(surface)
    cursor
  end

  def initialize(pdf, info, scale)
    @size = (POINTS * scale).to_i
    @pixels = IO::Buffer.new(@size * @size * 4)
    draw(pdf, info, scale)
    unpremultiply
  end

  # An SDL surface over the pixels (SDL copies them into the cursor).
  def surface
    SDL.SDL_CreateSurfaceFrom(@size, @size, SDL::PIXELFORMAT_ARGB8888, @pixels, @size * 4)
  end

  private

  def draw(pdf, info, scale)
    url = CoreGraphics.CFURLCreateFromFileSystemRepresentation(nil, pdf, pdf.bytesize, false)
    document = CoreGraphics.CGPDFDocumentCreateWithURL(url)
    space = CoreGraphics.CGColorSpaceCreateDeviceRGB
    context = CoreGraphics.CGBitmapContextCreate(@pixels, @size, @size, 8, @size * 4, space, CoreGraphics::PREMULTIPLIED_BGRA)
    shadow = CoreGraphics.CGColorCreateGenericRGB(0.0, 0.0, 0.0, info.shadow_opacity)
    CoreGraphics.CGContextSetShadowWithColor(context, info.shadow_x * scale, info.shadow_y * scale, info.blur * scale, shadow)
    CoreGraphics.CGContextScaleCTM(context, scale, scale)
    CoreGraphics.CGContextDrawPDFPage(context, CoreGraphics.CGPDFDocumentGetPage(document, 1))
    CoreGraphics.CGColorRelease(shadow)
    CoreGraphics.CGContextRelease(context)
    CoreGraphics.CGColorSpaceRelease(space)
    CoreGraphics.CGPDFDocumentRelease(document)
    CoreGraphics.CFRelease(url)
  end

  # CoreGraphics draws with alpha multiplied in; SDL's cursors want it
  # straight.
  def unpremultiply
    (0...@size * @size).each do |index|
      color = @pixels.get_value(:u32, index * 4)
      alpha = color >> 24
      next if alpha == 0 || alpha == 255
      red = ((color >> 16) & 255) * 255 / alpha
      green = ((color >> 8) & 255) * 255 / alpha
      blue = (color & 255) * 255 / alpha
      @pixels.set_value(:u32, index * 4, (alpha << 24) | (red << 16) | (green << 8) | blue)
    end
  end
end

# What a cursor's info.plist says: the hot spot (points from the top
# left), and the shadow's blur, offset and opacity.
class CursorInfo
  attr_reader :hot_x, :hot_y, :blur, :shadow_x, :shadow_y, :shadow_opacity

  def initialize(plist)
    @plist = plist
    @hot_x = number("hotx").to_i
    @hot_y = number("hoty").to_i
    @blur = number("blur")
    @shadow_x = number("shadowoffsetx")
    @shadow_y = number("shadowoffsety")
    colors = @plist.index("<key>shadowcolor</key>")
    @shadow_opacity = colors ? nth_value(colors, 4) : 0.0
  end

  private

  # The <real> or <integer> right after <key>name</key>; 0 when absent.
  def number(name)
    at = @plist.index("<key>#{name}</key>")
    at ? nth_value(at, 1) : 0.0
  end

  # The nth number value after position at.
  def nth_value(at, nth)
    position = at
    value = 0.0
    nth.times do
      open = next_number_tag(position)
      return 0.0 if open < 0
      start = @plist.index(">", open) + 1
      finish = @plist.index("<", start)
      value = @plist[start, finish - start].to_f
      position = finish
    end
    value
  end

  # Where the next <real> or <integer> starts after position; -1 if none.
  def next_number_tag(position)
    real = @plist.index("<real>", position) || -1
    integer = @plist.index("<integer>", position) || -1
    return integer if real < 0
    return real if integer < 0
    [real, integer].min
  end
end

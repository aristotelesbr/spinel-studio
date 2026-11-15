# Text drawn with SDL3_ttf onto a Canvas, in a font the theme names.
module TTF
  ffi_lib "SDL3_ttf"
  ffi_cflags "-L/opt/homebrew/lib"

  ffi_func :TTF_Init, [], :bool
  ffi_func :TTF_OpenFontWithProperties, [:uint32], :ptr
  ffi_func :TTF_GetFontStyleName, [:ptr], :str
  ffi_func :TTF_CloseFont, [:ptr], :void
  ffi_func :TTF_GetStringSize, [:ptr, :str, :size_t, :ptr, :ptr], :bool
  # SDL_Color is 4 bytes passed by value, which the arm64 calling
  # convention carries in one register exactly like a uint32 (see #rgba).
  ffi_func :TTF_RenderText_Blended, [:ptr, :str, :size_t, :uint32], :ptr
end

# The system fonts are variable fonts: opened plainly they come in their
# first named instance (SF Mono's is Light, which reads thin on a dark
# panel). FreeType takes the instance from the high bits of the face
# number, and each font numbers its weights its own way, so the weight
# is looked up by name.
class Typeface
  INSTANCES_TRIED = 16

  # sizes in pixels: the small and the large text; font: a FontChoice
  # (the file and the weight's name).
  def initialize(small_size, large_size, font)
    @path = font.path
    TTF.TTF_Init
    @instance = instance_named(font.weight)
    @small = open_font(small_size.to_f)
    @large = open_font(large_size.to_f)
    @width = IO::Buffer.new(4)
    @height = IO::Buffer.new(4)
    @place = IO::Buffer.new(16)
  end

  # [width, height] of the text in pixels.
  def measure(text, large)
    TTF.TTF_GetStringSize(large ? @large : @small, text, text.bytesize, @width, @height)
    [@width.get_value(:s32, 0), @height.get_value(:s32, 0)]
  end

  # Draws the text with its top-left corner at (x, y) of the canvas.
  def draw(canvas, text, x, y, large, color)
    glyphs = TTF.TTF_RenderText_Blended(large ? @large : @small, text, text.bytesize, rgba(color))
    target = SDL.SDL_CreateSurfaceFrom(canvas.width, canvas.height, SDL::PIXELFORMAT_ARGB8888,
                                       canvas.pixels, canvas.width * 4)
    SDL.SDL_BlitSurface(glyphs, nil, target, SDL.rect(@place, x, y, 0, 0))
    SDL.SDL_DestroySurface(target)
    SDL.SDL_DestroySurface(glyphs)
  end

  private

  # 0xAARRGGBB as SDL_Color's bytes in memory order: r, g, b, a.
  def rgba(color)
    red = (color >> 16) & 0xFF
    green = (color >> 8) & 0xFF
    blue = color & 0xFF
    alpha = (color >> 24) & 0xFF
    red | (green << 8) | (blue << 16) | (alpha << 24)
  end

  def open_font(size)
    open_instance(size, @instance)
  end

  # The first named instance (after the default, 0) called weight, or
  # the default when there is none.
  def instance_named(weight)
    (1...INSTANCES_TRIED).each do |instance|
      font = open_instance(12.0, instance)
      return 0 if font == nil
      name = TTF.TTF_GetFontStyleName(font)
      TTF.TTF_CloseFont(font)
      return instance if name == weight
    end
    0
  end

  def open_instance(size, instance)
    properties = SDL.SDL_CreateProperties
    SDL.SDL_SetStringProperty(properties, "SDL_ttf.font.create.filename", @path)
    SDL.SDL_SetFloatProperty(properties, "SDL_ttf.font.create.size", size)
    SDL.SDL_SetNumberProperty(properties, "SDL_ttf.font.create.face", instance << 16)
    font = TTF.TTF_OpenFontWithProperties(properties)
    SDL.SDL_DestroyProperties(properties)
    font
  end
end

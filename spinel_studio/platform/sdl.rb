# The slice of SDL3 the app uses: borderless, transparent, always-on-top
# windows, streaming textures, a few rectangles and events.
module SDL
  ffi_lib "SDL3"
  ffi_cflags "-L/opt/homebrew/lib"

  ffi_func :SDL_Init,                [:uint32], :bool
  ffi_func :SDL_GetError,            [], :str
  ffi_func :SDL_SetHint,             [:str, :str], :bool
  ffi_func :SDL_CreateWindow,        [:str, :int, :int, :long], :ptr
  ffi_func :SDL_DestroyWindow,       [:ptr], :void
  ffi_func :SDL_ShowWindow,          [:ptr], :bool
  ffi_func :SDL_HideWindow,          [:ptr], :bool
  ffi_func :SDL_RaiseWindow,         [:ptr], :bool
  ffi_func :SDL_SetWindowPosition,   [:ptr, :int, :int], :bool
  ffi_func :SDL_GetWindowProperties, [:ptr], :uint32
  ffi_func :SDL_GetPointerProperty,  [:uint32, :str, :ptr], :ptr
  ffi_func :SDL_GetPrimaryDisplay,   [], :uint32
  ffi_func :SDL_GetDisplayBounds,    [:uint32, :ptr], :bool
  ffi_func :SDL_GetGlobalMouseState, [:ptr, :ptr], :uint32
  ffi_func :SDL_CreateRenderer,      [:ptr, :ptr], :ptr
  ffi_func :SDL_DestroyRenderer,     [:ptr], :void
  ffi_func :SDL_GetRenderOutputSize, [:ptr, :ptr, :ptr], :bool
  ffi_func :SDL_CreateTexture,       [:ptr, :uint32, :int, :int, :int], :ptr
  ffi_func :SDL_DestroyTexture,      [:ptr], :void
  ffi_func :SDL_UpdateTexture,       [:ptr, :ptr, :ptr, :int], :bool
  ffi_func :SDL_SetTextureBlendMode, [:ptr, :uint32], :bool
  ffi_func :SDL_SetRenderDrawBlendMode, [:ptr, :uint32], :bool
  ffi_func :SDL_SetRenderDrawColor,  [:ptr, :uint8, :uint8, :uint8, :uint8], :bool
  ffi_func :SDL_RenderFillRect,      [:ptr, :ptr], :bool
  ffi_func :SDL_RenderRect,          [:ptr, :ptr], :bool
  ffi_func :SDL_RenderClear,         [:ptr], :bool
  ffi_func :SDL_RenderTexture,       [:ptr, :ptr, :ptr, :ptr], :bool
  ffi_func :SDL_RenderPresent,       [:ptr], :bool
  ffi_func :SDL_PollEvent,           [:ptr], :bool
  ffi_func :SDL_CreateSurfaceFrom,   [:int, :int, :uint32, :ptr, :int], :ptr
  ffi_func :SDL_BlitSurface,         [:ptr, :ptr, :ptr, :ptr], :bool
  ffi_func :SDL_DestroySurface,      [:ptr], :void
  ffi_func :SDL_CreateSystemCursor,  [:uint32], :ptr
  ffi_func :SDL_SetCursor,           [:ptr], :bool
  ffi_func :SDL_GetScancodeName,     [:uint32], :str
  ffi_callback :dialog_answered, [:ptr, :ptr, :int], :void
  ffi_func :SDL_ShowSaveFileDialog,  [:dialog_answered, :ptr, :ptr, :ptr, :int, :str], :void
  ffi_read_ptr :first_pointer, 0
  ffi_func :SDL_CreateColorCursor,   [:ptr, :int, :int], :ptr
  ffi_func :SDL_DestroyCursor,       [:ptr], :void
  ffi_func :SDL_AddSurfaceAlternateImage, [:ptr, :ptr], :bool
  ffi_func :SDL_CreateProperties,    [], :uint32
  ffi_func :SDL_SetStringProperty,   [:uint32, :str, :str], :bool
  ffi_func :SDL_SetFloatProperty,    [:uint32, :str, :float], :bool
  ffi_func :SDL_SetNumberProperty,   [:uint32, :str, :long], :bool
  ffi_func :SDL_DestroyProperties,   [:uint32], :void
  ffi_func :SDL_Delay,               [:uint32], :void
  ffi_func :SDL_Quit,                [], :void

  INIT_VIDEO              = 0x20
  PIXELFORMAT_ARGB8888    = 0x16362004
  TEXTUREACCESS_STREAMING = 1
  BLENDMODE_BLEND         = 0x1
  BLENDMODE_PREMULTIPLIED = 0x10

  WINDOW_FULLSCREEN    = 0x1
  WINDOW_BORDERLESS    = 0x10
  WINDOW_HIGH_DENSITY  = 0x2000
  WINDOW_ALWAYS_ON_TOP = 0x10000
  WINDOW_UTILITY       = 0x20000
  WINDOW_TRANSPARENT   = 0x40000000
  WINDOW_NOT_FOCUSABLE = 0x80000000

  QUIT        = 0x100
  KEYDOWN     = 0x300
  MOUSEMOTION = 0x400
  MOUSEDOWN   = 0x401
  MOUSEUP     = 0x402
  WINDOW_CLOSE_REQUESTED = 0x210
  SCANCODE_ESCAPE = 41

  CURSOR_DEFAULT = 0
  CURSOR_EW_RESIZE = 7
  CURSOR_MOVE = 9      # a closed hand on macOS
  CURSOR_POINTER = 11

  # Main display size in points: [width, height].
  def self.display_size
    b = IO::Buffer.new(16)
    SDL.SDL_GetDisplayBounds(SDL.SDL_GetPrimaryDisplay, b)
    [b.get_value(:s32, 8), b.get_value(:s32, 12)]
  end

  # Renderer output size in pixels: [width, height].
  def self.output_size(renderer)
    w = IO::Buffer.new(4)
    h = IO::Buffer.new(4)
    SDL.SDL_GetRenderOutputSize(renderer, w, h)
    [w.get_value(:s32, 0), h.get_value(:s32, 0)]
  end

  def self.global_mouse
    x = IO::Buffer.new(4)
    y = IO::Buffer.new(4)
    SDL.SDL_GetGlobalMouseState(x, y)
    [x.get_value(:f32, 0).to_i, y.get_value(:f32, 0).to_i]
  end

  def self.cocoa_window(window)
    SDL.SDL_GetPointerProperty(SDL.SDL_GetWindowProperties(window), "SDL.window.cocoa.window", nil)
  end

  # SDL_Rect as a 16-byte buffer.
  def self.rect(buf, x, y, w, h)
    buf.set_value(:s32, 0, x.to_i)
    buf.set_value(:s32, 4, y.to_i)
    buf.set_value(:s32, 8, w.to_i)
    buf.set_value(:s32, 12, h.to_i)
    buf
  end

  # SDL_FRect as a 16-byte buffer.
  def self.frect(buf, x, y, w, h)
    buf.set_value(:f32, 0, x.to_f)
    buf.set_value(:f32, 4, y.to_f)
    buf.set_value(:f32, 8, w.to_f)
    buf.set_value(:f32, 12, h.to_f)
    buf
  end
end

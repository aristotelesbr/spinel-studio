# A window with its renderer, in the shape of Gosu::Window: a subclass
# overrides the hooks (update, draw, needs_redraw?, the mouse and key
# events) and #show runs the loop until #close. Positions and sizes are
# points; the window turns them into pixels for its screen.
class Window
  attr_reader :width, :height, :scale

  # frame_delay_ms: the pause between turns of the loop.
  def initialize(title, width, height, flags, frame_delay_ms)
    @frame_delay_ms = frame_delay_ms
    @width = width
    @height = height
    @window = SDL.SDL_CreateWindow(title, width, height, flags | SDL::WINDOW_HIGH_DENSITY)
    @renderer = SDL.SDL_CreateRenderer(@window, nil)
    SDL.SDL_SetRenderDrawBlendMode(@renderer, SDL::BLENDMODE_BLEND)
    @scale = SDL.output_size(@renderer)[0].to_f / width
    @rect = IO::Buffer.new(16)
    @event = Event.new
    @textures = []
    @open = false
  end

  # Runs the loop: events, update, draw when needed, until #close.
  def show
    @open = true
    while @open
      dispatch(@event) while @event.poll
      update
      if needs_redraw?
        draw
        present
      end
      SDL.SDL_Delay(@frame_delay_ms)
    end
  end

  def close
    @open = false
  end

  # Frees the window, its renderer and every texture made with #texture.
  def destroy
    @textures.each(&:destroy)
    SDL.SDL_DestroyRenderer(@renderer)
    SDL.SDL_DestroyWindow(@window)
  end

  # Hooks for subclasses.
  def update; end
  def draw; end
  def mouse_down(_x, _y, _button); end
  def mouse_move(_x, _y); end
  def mouse_up(_x, _y, _button); end
  def key_down(_key, _modifiers); end

  def needs_redraw?
    true
  end

  def close_requested
    close
  end

  # A texture of pixel_width x pixel_height, freed with the window.
  # premultiplied: its pixels have alpha already multiplied in (Canvas).
  def texture(pixel_width, pixel_height, premultiplied = false)
    texture = Texture.new(@renderer, pixel_width, pixel_height, premultiplied)
    @textures << texture
    texture
  end

  # Draws the whole texture into the rectangle, in points.
  def copy(texture, x, y, width, height)
    SDL.SDL_RenderTexture(@renderer, texture.handle, nil, points_rect(x, y, width, height))
  end

  # Fills the rectangle with an 0xAARRGGBB color.
  def fill(x, y, width, height, color)
    draw_color(color)
    SDL.SDL_RenderFillRect(@renderer, points_rect(x, y, width, height))
  end

  # A 1-pixel line around the rectangle, grow pixels outside it.
  def outline(x, y, width, height, grow, color)
    draw_color(color)
    SDL.SDL_RenderRect(@renderer, SDL.frect(@rect, x * @scale - grow, y * @scale - grow,
                                            width * @scale + 2 * grow, height * @scale + 2 * grow))
  end

  def clear(color)
    draw_color(color)
    SDL.SDL_RenderClear(@renderer)
  end

  def present
    SDL.SDL_RenderPresent(@renderer)
  end

  # Window position on screen, in points.
  def move_to(x, y)
    SDL.SDL_SetWindowPosition(@window, x, y)
  end

  def hide
    SDL.SDL_HideWindow(@window)
  end

  def reveal
    SDL.SDL_ShowWindow(@window)
  end

  def raise_to_front
    SDL.SDL_RaiseWindow(@window)
  end

  # Asks where to save, with the system's Save panel on this window,
  # suggesting path; the answer comes later, through SaveDialog.
  def ask_save_path(path)
    SaveDialog.open(@window, path)
  end

  # The macOS window number, to leave this window out of a capture.
  def number
    ScreenCapture.studio_window_number(SDL.cocoa_window(@window))
  end

  # Clicks go through to whatever is below.
  def ignore_mouse
    ScreenCapture.studio_window_ignore_mouse(SDL.cocoa_window(@window))
  end

  # Takes events without acting on them for milliseconds (lets a hide
  # or a show happen before something else looks at the screen).
  def wait(milliseconds)
    waited = 0
    while waited < milliseconds
      nil while @event.poll
      SDL.SDL_Delay(10)
      waited += 10
    end
  end

  private

  def dispatch(event)
    if event.quit? then close_requested
    elsif event.mouse_down? then mouse_down(event.x, event.y, event.button)
    elsif event.mouse_move? then mouse_move(event.x, event.y)
    elsif event.mouse_up? then mouse_up(event.x, event.y, event.button)
    elsif event.key_down? then key_down(event.key, event.modifiers)
    end
  end

  def points_rect(x, y, width, height)
    SDL.frect(@rect, x * @scale, y * @scale, width * @scale, height * @scale)
  end

  def draw_color(color)
    SDL.SDL_SetRenderDrawColor(@renderer, (color >> 16) & 255, (color >> 8) & 255, color & 255, (color >> 24) & 255)
  end
end

# Pixels on the graphics card that a Window draws (ruby-sdl2's
# SDL2::Texture): filled from a Canvas or any BGRA buffer with #update.
class Texture
  attr_reader :width, :height, :handle

  def initialize(renderer, width, height, premultiplied)
    @width = width
    @height = height
    @handle = SDL.SDL_CreateTexture(renderer, SDL::PIXELFORMAT_ARGB8888, SDL::TEXTUREACCESS_STREAMING, width, height)
    SDL.SDL_SetTextureBlendMode(@handle, SDL::BLENDMODE_PREMULTIPLIED) if premultiplied
  end

  def update(pixels)
    SDL.SDL_UpdateTexture(@handle, nil, pixels, @width * 4)
  end

  def destroy
    SDL.SDL_DestroyTexture(@handle)
  end
end

# An SDL event, read through named fields instead of byte offsets (the
# role SDL2::Event plays in ruby-sdl2). One object is filled again by
# each #poll, so the event loop allocates nothing.
class Event
  def initialize
    @buffer = IO::Buffer.new(128)
  end

  # Takes the next pending event; false when there is none.
  def poll
    SDL.SDL_PollEvent(@buffer)
  end

  def type
    @buffer.get_value(:u32, 0)
  end

  # The app is quitting or the window's close button was pressed.
  def quit?
    type == SDL::QUIT || type == SDL::WINDOW_CLOSE_REQUESTED
  end

  def mouse_down?
    type == SDL::MOUSEDOWN
  end

  def mouse_up?
    type == SDL::MOUSEUP
  end

  def mouse_move?
    type == SDL::MOUSEMOTION
  end

  def key_down?
    type == SDL::KEYDOWN
  end

  # Pointer position in points.
  def x
    @buffer.get_value(:f32, 28).to_i
  end

  def y
    @buffer.get_value(:f32, 32).to_i
  end

  # 1 left, 2 middle, 3 right.
  def button
    @buffer.get_value(:U8, 24)
  end

  # The key's scancode (where it is on the keyboard).
  def key
    @buffer.get_value(:u32, 24)
  end

  # The modifier keys held (SDL_Keymod).
  def modifiers
    @buffer.get_value(:u16, 32)
  end
end

# The mouse pointer's shapes over the timeline, by what
# TimelineView#pointing_at says is under it: the arrow, an open hand on
# what can be dragged (closed while it is held), the resize arrows on an
# edge and the pointing hand on a clip.
class Pointers
  # The hands are macOS's own (SystemCursor, from the folders the app
  # settings list); SDL's nearest cursors stand in when they are missing.
  def initialize(scale, cursor_folders)
    @arrow = SDL.SDL_CreateSystemCursor(SDL::CURSOR_DEFAULT)
    @resize = SDL.SDL_CreateSystemCursor(SDL::CURSOR_EW_RESIZE)
    @pointing_hand = SDL.SDL_CreateSystemCursor(SDL::CURSOR_POINTER)
    @open_hand = SystemCursor.create("openhand", cursor_folders, scale)
    @open_hand = SDL.SDL_CreateSystemCursor(SDL::CURSOR_POINTER) if @open_hand == nil
    @closed_hand = SystemCursor.create("closedhand", cursor_folders, scale)
    @closed_hand = SDL.SDL_CreateSystemCursor(SDL::CURSOR_MOVE) if @closed_hand == nil
  end

  # pointing_at: :nothing, :playhead, :edge, :clip or :zoom.
  def show(pointing_at)
    SDL.SDL_SetCursor(shape(pointing_at))
  end

  def grab
    SDL.SDL_SetCursor(@closed_hand)
  end

  def destroy
    SDL.SDL_SetCursor(nil)
    [@arrow, @resize, @pointing_hand, @open_hand, @closed_hand].each { |cursor| SDL.SDL_DestroyCursor(cursor) }
  end

  private

  def shape(pointing_at)
    case pointing_at
    when :playhead, :zoom then @open_hand
    when :edge then @resize
    when :clip then @pointing_hand
    else @arrow
    end
  end
end

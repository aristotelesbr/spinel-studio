# The system's Save panel (NSSavePanel on macOS), through SDL3. SDL shows
# it attached to a window and answers later, from its event loop, by
# calling .answered with the list of chosen paths; the window reads
# #state and #path in its update.
module SaveDialog
  @state = :closed
  @path = ""

  # state: :closed, :open, :chosen (see #path), :cancelled or :failed.
  def self.state
    @state
  end

  def self.path
    @path
  end

  def self.open(window, suggested_path)
    @state = :open
    @path = ""
    SDL.SDL_ShowSaveFileDialog(SaveDialog.method(:answered), nil, window, nil, 0, suggested_path)
  end

  # The answer was read; back to closed.
  def self.reset
    @state = :closed
  end

  # SDL's callback: list is a C array of paths, NULL on an error, empty
  # (its first entry NULL) when the panel was cancelled.
  def self.answered(_userdata, list, _filter)
    return @state = :failed if list == nil
    first = SDL.first_pointer(list)
    return @state = :cancelled if first == nil
    @path = CString.strstr(first, "")
    @state = :chosen
  end
end

# Reads a C string a callback hands over: strstr(p, "") returns p itself,
# and a :str return copies it into a Ruby String.
module CString
  ffi_func :strstr, [:ptr, :str], :str
end

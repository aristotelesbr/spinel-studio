# The system's Save and Open panels (NSSavePanel and NSOpenPanel on
# macOS), through SDL3. SDL answers later, from its event loop, by
# calling .answered with the list of chosen paths; the window that asked
# reads #state and #path in its update. One panel is open at a time.
module FileDialog
  @state = :closed
  @path = ""

  # state: :closed, :open, :chosen (see #path), :cancelled or :failed.
  def self.state
    @state
  end

  def self.path
    @path
  end

  # Asks where to save, attached to window, suggesting suggested_path.
  def self.save(window, suggested_path)
    @state = :open
    @path = ""
    SDL.SDL_ShowSaveFileDialog(FileDialog.method(:answered), nil, window, nil, 0, suggested_path)
  end

  # Asks for a file to open, starting in folder. window may be nil: the
  # panel then opens on its own.
  def self.open(window, folder)
    @state = :open
    @path = ""
    SDL.SDL_ShowOpenFileDialog(FileDialog.method(:answered), nil, window, nil, 0, folder, false)
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

# Reads a C string SDL hands over: strstr(p, "") returns p itself, and a
# :str return copies it into a Ruby String.
module CString
  ffi_func :strstr, [:ptr, :str], :str
  ffi_func :memcpy, [:ptr, :ptr, :size_t], :ptr
end

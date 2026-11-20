# Linux has no cursor files like macOS's: Pointers falls back to SDL's
# own hands when this gives none.
class SystemCursor
  def self.create(_name, _folders, _scale)
    nil
  end
end

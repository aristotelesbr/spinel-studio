# The editor's keyboard shortcuts, from the settings: each action has
# one or more keys written like "S", "Backspace" or "Shift+Cmd+Z". Key
# names are SDL's; Cmd means Cmd or Ctrl.
class Shortcuts
  ACTIONS = { "play" => :play, "split" => :split, "delete" => :delete, "zoomIn" => :zoom_in,
              "zoomOut" => :zoom_out, "undo" => :undo, "redo" => :redo, "save" => :save, "cancel" => :cancel }.freeze

  def initialize(data)
    @list = []
    ACTIONS.each do |name, action|
      data.fetch(name, []).each { |text| @list << Shortcut.new(action, text.to_s) }
    end
  end

  # The action of a key pressed with these modifiers, or :none.
  def action_for(key_name, command, shift, option)
    found = @list.find { |shortcut| shortcut.matches?(key_name, command, shift, option) }
    found ? found.action : :none
  end

  # How the first key of an action is shown, as "⇧⌘Z" or "⌫" ("" for none).
  def label(action)
    found = @list.find { |shortcut| shortcut.action == action }
    found ? found.label : ""
  end
end

# One key and its modifiers, for one action.
class Shortcut
  SYMBOLS = { "Backspace" => "⌫", "Delete" => "⌦", "Return" => "↩", "Escape" => "esc", "Tab" => "⇥",
              "Up" => "↑", "Down" => "↓", "Left" => "←", "Right" => "→" }.freeze

  attr_reader :action

  def initialize(action, text)
    @action = action
    parts = text.split("+")
    @key = parts.last.to_s
    @command = parts.include?("Cmd") || parts.include?("Ctrl")
    @shift = parts.include?("Shift")
    @option = parts.include?("Option")
  end

  def matches?(key_name, command, shift, option)
    key_name.downcase == @key.downcase && command == @command && shift == @shift && option == @option
  end

  def label
    (@shift ? "⇧" : "") + (@option ? "⌥" : "") + (@command ? "⌘" : "") + SYMBOLS.fetch(@key, @key)
  end
end

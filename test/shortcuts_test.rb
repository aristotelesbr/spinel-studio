require_relative "test_helper"

class ShortcutsTest < Minitest::Test
  def setup
    @shortcuts = SETTINGS.editor.shortcuts
  end

  def test_keys_find_their_actions
    assert_equal :split, @shortcuts.action_for("S", false, false, false)
    assert_equal :delete, @shortcuts.action_for("Backspace", false, false, false)
    assert_equal :delete, @shortcuts.action_for("Delete", false, false, false)
    assert_equal :play, @shortcuts.action_for("Space", false, false, false)
  end

  def test_modifiers_must_match
    assert_equal :undo, @shortcuts.action_for("Z", true, false, false)
    assert_equal :redo, @shortcuts.action_for("Z", true, true, false)
    assert_equal :none, @shortcuts.action_for("S", true, false, false)
  end

  def test_labels_show_the_first_key
    assert_equal "S", @shortcuts.label(:split)
    assert_equal "⌫", @shortcuts.label(:delete)
    assert_equal "⌘Z", @shortcuts.label(:undo)
    assert_equal "⇧⌘Z", @shortcuts.label(:redo)
    assert_equal "esc", @shortcuts.label(:cancel)
  end

  def test_shortcuts_come_from_the_settings
    custom = Shortcuts.new({ "split" => ["B"], "undo" => ["Ctrl+U"] })
    assert_equal :split, custom.action_for("b", false, false, false)
    assert_equal :none, custom.action_for("S", false, false, false)
    assert_equal "⌘U", custom.label(:undo)
  end
end

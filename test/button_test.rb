require_relative "test_helper"

class ButtonTest < Minitest::Test
  def test_a_button_with_a_shortcut_shows_its_key
    typeface = FakeTypeface.new
    Button.new(0, 0, 92, 32, "Split", :secondary, :split, "S").paint(Canvas.new(184, 64), typeface, SETTINGS.theme, 2.0, false, false)
    assert_equal %w[Split S], typeface.drawn
  end

  def test_a_button_without_a_shortcut_shows_only_its_label
    typeface = FakeTypeface.new
    Button.new(0, 0, 104, 32, "Export", :primary, :export).paint(Canvas.new(208, 64), typeface, SETTINGS.theme, 2.0, false, false)
    assert_equal %w[Export], typeface.drawn
  end
end

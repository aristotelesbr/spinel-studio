require_relative "test_helper"

class SystemCursorTest < Minitest::Test
  PLIST = <<~XML
    <dict>
    	<key>blur</key>
    	<real>2</real>
    	<key>hotx</key>
    	<real>15</real>
    	<key>hoty</key>
    	<integer>16</integer>
    	<key>shadowcolor</key>
    	<array>
    		<real>0</real>
    		<real>0</real>
    		<real>0</real>
    		<real>0.45</real>
    	</array>
    	<key>shadowoffsetx</key>
    	<real>0</real>
    	<key>shadowoffsety</key>
    	<real>-1</real>
    </dict>
  XML

  def test_the_plist_gives_the_hot_spot_and_the_shadow
    info = CursorInfo.new(PLIST)
    assert_equal [15, 16], [info.hot_x, info.hot_y]
    assert_in_delta 2.0, info.blur
    assert_in_delta(-1.0, info.shadow_y)
    assert_in_delta 0.45, info.shadow_opacity
  end

  def test_a_missing_key_reads_as_zero
    assert_in_delta 0.0, CursorInfo.new("<dict></dict>").blur
  end
end

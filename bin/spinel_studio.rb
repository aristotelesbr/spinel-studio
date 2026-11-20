# Spinel Studio: screen recordings with a wallpaper, rounded corners, a
# drop shadow, a smooth cursor and zooms, edited on a timeline, compiled
# by Spinel.
#
#   spinel_studio                       the floating toolbar (Display / Area)
#   spinel_studio record DIR [SECONDS]  record from the terminal
#   spinel_studio edit DIR              open a take in the editor
#   spinel_studio export DIR [FILE]     write the video (DIR/studio.mp4)
#
# ffmpeg encodes and decodes video; the rest is this program.

require_relative "../spinel_studio/platform/macos"
require_relative "../spinel_studio"
require_relative "../spinel_studio/main"

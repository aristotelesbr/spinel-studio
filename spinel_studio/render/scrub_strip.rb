# Small frames for dragging the playhead and for the clip track's
# thumbnails. When the editor opens, an ffmpeg in the background writes
# the take as small raw frames (the thumbnails' width and frame rate in
# the settings) to a temporary file beside it; reading one back is
# instant. Removed on close.
class ScrubStrip
  attr_reader :width, :height, :out_width, :out_height

  def initialize(recording, settings)
    @path = "#{recording.dir}/.scrub.raw"
    editor = settings.editor
    @width = editor.thumbnail_width
    @fps = editor.thumbnail_fps
    @out_width = editor.scrub_width
    @out_height = editor.scrub_height
    @height = (recording.frame_height * @width / recording.frame_width / 2) * 2
    @frame_size = @width * @height * 4
    @frame = IO::Buffer.new(@frame_size)
    @composer = FrameComposer.new(recording, settings.render, @width, @height, @out_width, @out_height)
    File.delete(@path) if File.exist?(@path)
    @pid = Process.spawn("#{FFmpeg.ffmpeg} -v error -y -i #{FFmpeg.quote(recording.screen)} -vf fps=#{@fps},scale=#{@width}:#{@height} " \
                         "-f rawvideo -pix_fmt bgra #{FFmpeg.quote(@path)}", err: "/dev/null")
  end

  def pixels
    @composer.pixels
  end

  # Composes the strip frame nearest to time; false if not written yet.
  def show(time)
    return false unless read(time, @frame)
    @composer.compose_still(@frame, time)
    true
  end

  # The raw strip frame nearest to time into buffer (width x height).
  def read(time, buffer)
    offset = (time * @fps).to_i * @frame_size
    return false unless File.exist?(@path) && File.size(@path) >= offset + @frame_size
    File.open(@path, "rb") { |file| buffer.pread(file, offset, @frame_size) }
    true
  end

  def close
    Process.kill("TERM", @pid) rescue nil
    Process.wait(@pid) rescue nil
    File.delete(@path) if File.exist?(@path)
  end
end

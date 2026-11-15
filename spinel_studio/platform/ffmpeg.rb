# ffmpeg moves pixels in and out of the program: encoding the captured
# frames, decoding the recording into raw BGRA frames and encoding the
# finished video.
# Every effect in between runs in Spinel.
#
# The tools' paths come from the settings (an app opened from Finder does
# not get the shell's PATH); #configure sets them once at start.
module FFmpeg
  @ffmpeg = "ffmpeg"
  @ffprobe = "ffprobe"

  def self.configure(app)
    @ffmpeg = app.ffmpeg
    @ffprobe = app.ffprobe
  end

  def self.ffmpeg
    @ffmpeg
  end

  # path in single quotes for the shell, whatever it contains (a name
  # typed in the Save panel can have a quote).
  def self.quote(path)
    "'" + path.gsub("'") { "'\\''" } + "'"
  end

  # Encodes raw NV12 frames written to the returned pipe into path.
  def self.recorder(path, width, height, fps, codec, bitrate)
    r, w = IO.pipe
    pid = Process.spawn("#{@ffmpeg} -v error -y -f rawvideo -pix_fmt nv12 -s #{width}x#{height} -r #{fps} -i - " \
                        "-c:v #{codec} -b:v #{bitrate} #{FFmpeg.quote(path)}", in: r)
    r.close
    [pid, w]
  end

  # [width, height] of the first video stream.
  def self.frame_size(path)
    `#{@ffprobe} -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 #{FFmpeg.quote(path)}`.strip.split("x").map(&:to_i)
  end

  def self.duration(path)
    `#{@ffprobe} -v error -show_entries format=duration -of csv=p=0 #{FFmpeg.quote(path)}`.strip.to_f
  end

  def self.decoder(path, fps)
    r, w = IO.pipe
    pid = Process.spawn("#{@ffmpeg} -v error -i #{FFmpeg.quote(path)} -vf fps=#{fps} -f rawvideo -pix_fmt bgra -", out: w)
    w.close
    [pid, r]
  end

  # Raw BGRA frames from start seconds on.
  def self.preview_decoder(path, fps, start)
    r, w = IO.pipe
    pid = Process.spawn("#{@ffmpeg} -v error -ss #{start.round(3)} -i #{FFmpeg.quote(path)} " \
                        "-vf fps=#{fps} -f rawvideo -pix_fmt bgra -", out: w, err: "/dev/null")
    w.close
    [pid, r]
  end

  def self.stop(pid, pipe)
    pipe.close
    Process.kill("TERM", pid)
    Process.wait(pid)
  end

  def self.encoder(path, width, height, fps, codec, bitrate)
    r, w = IO.pipe
    pid = Process.spawn("#{@ffmpeg} -v error -y -f rawvideo -pix_fmt bgra -s #{width}x#{height} -r #{fps} -i - " \
                        "-c:v #{codec} -b:v #{bitrate} -pix_fmt yuv420p #{FFmpeg.quote(path)}", in: r)
    r.close
    [pid, w]
  end

  # Fills buf with exactly size bytes from io; false at end of stream.
  def self.read_frame(io, buf, size)
    got = 0
    while got < size
      n = buf.read(io, size - got, got)
      return false if n <= 0
      got += n
    end
    true
  end

  # A pipe write can take fewer bytes than asked, so keep writing.
  def self.write_frame(io, buf, size)
    done = 0
    while done < size
      n = buf.write(io, size - done, done)
      raise "encoder closed the pipe" if n <= 0
      done += n
    end
  end
end

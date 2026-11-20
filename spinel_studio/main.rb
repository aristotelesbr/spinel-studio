# What the program does with its arguments, on every system. The file in
# bin/ loads the system's side of platform/ and the code, then this.
settings = Settings.load
FFmpeg.configure(settings.app)
command = ARGV.empty? ? "app" : ARGV[0]
if command == "app"
  SDL.SDL_SetHint("SDL_MOUSE_FOCUS_CLICKTHROUGH", "1")
  SDL.SDL_Init(SDL::INIT_VIDEO)
  app = App.new(settings)
  app.show
  app.destroy
  SDL.SDL_Quit
elsif command == "record" && ARGV.size >= 2
  SDL.SDL_Init(SDL::INIT_VIDEO)
  recorder = Recorder.new(ARGV[1], [], [], settings.recording)
  seconds = ARGV.size > 2 ? ARGV[2].to_f : 10.0
  exit 1 unless recorder.start
  puts "recording #{seconds}s..."
  while recorder.elapsed < seconds
    recorder.sample
    sleep 0.005
  end
  recorder.stop
  puts "saved #{ARGV[1]}"
elsif command == "edit" && ARGV.size >= 2
  SDL.SDL_Init(SDL::INIT_VIDEO)
  editor = Editor.new(ARGV[1], settings)
  snapshot = ENV["SPINEL_STUDIO_SNAPSHOT"]
  snapshot ? editor.snapshot(snapshot, 1.2) : editor.show
  editor.destroy
  SDL.SDL_Quit
elsif command == "export" && ARGV.size >= 2
  exporter = Exporter.new(Recording.new(ARGV[1], settings), settings, ARGV.size > 2 ? ARGV[2] : "#{ARGV[1]}/studio.mp4")
  while exporter.step
    puts "#{exporter.frames} frames" if exporter.frames % 60 == 0
  end
  exporter.finish
  puts "#{exporter.frames} frames -> #{exporter.path}"
else
  puts "usage: spinel_studio | spinel_studio record DIR [SECONDS] | spinel_studio edit DIR | spinel_studio export DIR [FILE]"
  exit 1
end

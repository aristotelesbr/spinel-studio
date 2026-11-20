# The editor that opens after a take, laid out like Cap's: the player on
# top, the timeline panel below. Every change is saved to
# project-config.json at once (Cap writes the same file as you edit), and
# can be undone.
#
# Keys (the editor settings' shortcuts) and buttons (TimelinePanel's)
# name the same actions; #perform carries them out.
class Editor < Window
  WIDTH = TimelinePanel::WIDTH
  PREVIEW_AREA = 650
  PREVIEW_MARGIN = 10
  HEIGHT = PREVIEW_AREA + TimelinePanel::HEIGHT
  KNOB = 12
  SHIFT = 0x0003     # SDL_KMOD_SHIFT
  OPTION = 0x0300    # SDL_KMOD_ALT
  COMMAND = 0x0CC0   # SDL_KMOD_CTRL | SDL_KMOD_GUI: Cmd, or Ctrl

  def initialize(dir, settings)
    super("Spinel Studio — #{ProjectFolder.name(dir, settings.recording.project_extension)}", WIDTH, HEIGHT, 0,
          settings.editor.frame_delay_ms)
    raise_to_front
    @settings = settings
    @editor = settings.editor
    @theme = settings.theme
    @recording = Recording.new(dir, settings)
    @view = TimelineView.new(@recording.timeline, @recording.duration, @editor)
    @history = History.new(@recording.timeline, @editor.history_limit)
    @player = Player.new(@recording, settings)
    @strip = ScrubStrip.new(@recording, settings)
    typeface = Typeface.new(@theme.small_text_size * scale, @theme.text_size * scale, @theme.font)
    @panel = TimelinePanel.new(scale, typeface, @view, @strip, @theme, @editor)
    @pointers = Pointers.new(scale, settings.app.system_cursors)
    @preview_texture = texture(settings.export.width, settings.export.height)
    @scrub_texture = texture(@strip.out_width, @strip.out_height)
    @panel_texture = texture(@panel.canvas.width, @panel.canvas.height)
    @clock_texture = texture(@panel.clock.width, @panel.clock.height)
    @knob = knob_texture
    @scrubbing = false
    @scrub_time = 0.0
    @gesture = :nothing
    @pointing_at = :nothing
    @dimmed = false
    @status = ""
    @hovered = nil
    @held = nil
    @last_clock_paint = 0.0
    @last_thumbnail_check = 0.0
    seek(0.0)
    paint_panel
  end

  def destroy
    @player.close
    @strip.close
    @pointers.destroy
    super
  end

  # For checking the look without a screen capture: waits for the
  # thumbnails, splits at time, paints, and writes the preview, the panel
  # and the clock as raw BGRA (prefix-preview.raw, ...).
  def snapshot(prefix, time)
    seek(time)
    60.times do
      @panel.refresh_thumbnails
      sleep 0.05
    end
    @view.split(time)
    @hovered = @panel.export
    paint_panel
    write_raw("#{prefix}-preview.raw", @player.pixels)
    write_raw("#{prefix}-panel.raw", @panel.canvas.pixels)
    write_raw("#{prefix}-clock.raw", @panel.clock.pixels)
    puts "panel #{@panel.canvas.width}x#{@panel.canvas.height}"
  end

  def update
    now = SpinelStudio.now
    take_save_answer
    advance_playback(now)
    refresh_thumbnails(now)
  end

  def draw
    clear(@theme.window)
    height = PREVIEW_AREA - 2 * PREVIEW_MARGIN
    width = height * @settings.export.width / @settings.export.height
    copy(@scrubbing ? @scrub_texture : @preview_texture, (WIDTH - width) / 2, PREVIEW_MARGIN, width, height)
    copy(@panel_texture, 0, PREVIEW_AREA, WIDTH, TimelinePanel::HEIGHT)
    copy(@clock_texture, TimelinePanel::TIME_LEFT, PREVIEW_AREA + TimelinePanel::HEADER_TOP,
         TimelinePanel::CLOCK_WIDTH, TimelinePanel::CONTROL_SIZE)
    draw_playhead
    fill(0, 0, WIDTH, HEIGHT, @theme.modal_shade) if @dimmed
  end

  def key_down(key, modifiers)
    perform(@editor.shortcuts.action_for(SDL.SDL_GetScancodeName(key), (modifiers & COMMAND) != 0,
                                         (modifiers & SHIFT) != 0, (modifiers & OPTION) != 0))
  end

  def mouse_down(x, y, _button)
    return perform(:play) if y < PREVIEW_AREA
    panel_y = y - PREVIEW_AREA
    @held = @panel.button_at(x, panel_y)
    return paint_panel if @held
    @history.record
    @gesture = @view.press(x, panel_y, playhead_time)
    @history.commit unless @gesture == :edit
    @pointers.grab if @gesture != :nothing && (@pointing_at == :playhead || @pointing_at == :zoom)
    start_scrub(x) if @gesture == :seek
    paint_panel
  end

  def mouse_move(x, y)
    case @gesture
    when :seek then scrub(x)
    when :edit
      @view.drag(x)
      paint_panel
    else hover(x, y)
    end
  end

  def mouse_up(x, y, _button)
    if @held
      clicked = @held.contains?(x, y - PREVIEW_AREA) ? @held.action : :none
      @held = nil
      paint_panel
      perform(clicked)
    elsif @gesture == :seek
      @scrubbing = false
      seek(@scrub_time)
      paint_panel
    elsif @gesture == :edit
      @view.release
      @history.commit
      changed
    end
    @gesture = :nothing
    @pointing_at = :none
    hover(x, y)
  end

  private

  # What a key or a button asked for.
  def perform(action)
    case action
    when :play then toggle_play
    when :split then edit { @view.split(playhead_time) }
    when :delete then edit { @view.delete_selected }
    when :zoom_in then edit { @view.change_amount(1) }
    when :zoom_out then edit { @view.change_amount(-1) }
    when :export then ask_where_to_export
    when :save then save
    when :undo then restore(@history.undo)
    when :redo then restore(@history.redo)
    end
  end

  # Every change is saved as it is made; Cmd+S saves again and says so.
  def save
    @recording.save
    @status = "Saved"
    paint_panel
  end

  def edit
    @history.record
    yield
    @history.commit
    changed
  end

  def restore(stepped)
    return unless stepped
    @view.deselect
    changed
  end

  # Saves the project and shows the change at the current time.
  def changed
    @status = ""
    @recording.save
    seek(playhead_time)
    paint_panel
  end

  # Pointer shape over the timeline, and the hover look of the buttons.
  def hover(x, y)
    panel_y = y - PREVIEW_AREA
    pointing_at = y >= PREVIEW_AREA ? @view.pointing_at(x, panel_y, playhead_time) : :nothing
    if pointing_at != @pointing_at
      @pointing_at = pointing_at
      @pointers.show(pointing_at)
    end
    hovered = y >= PREVIEW_AREA ? @panel.button_at(x, panel_y) : nil
    return if hovered.equal?(@hovered)
    @hovered = hovered
    paint_panel
  end

  def start_scrub(x)
    @player.pause
    @scrubbing = true
    scrub(x)
  end

  # The playhead follows the pointer at once; the preview shows the
  # strip frame until the release brings the sharp one.
  def scrub(x)
    @scrub_time = @view.time_at(x)
    @scrub_texture.update(@strip.pixels) if @strip.show(@scrub_time)
    paint_clock if SpinelStudio.now - @last_clock_paint >= @editor.clock_refresh
  end

  def toggle_play
    @player.toggle(SpinelStudio.now)
    show_preview
    paint_panel
  end

  def seek(time)
    @player.seek(time)
    show_preview
  end

  def advance_playback(now)
    return unless @player.playing?
    show_preview if @player.advance(now)
    return paint_panel unless @player.playing?
    paint_clock if now - @last_clock_paint >= @editor.clock_refresh
  end

  def show_preview
    @preview_texture.update(@player.pixels)
  end

  # The system's Save panel, suggesting the take's name in the export
  # folder; the export starts when a path comes back.
  def ask_where_to_export
    return if FileDialog.state == :open
    @player.pause
    paint_panel
    ask_save_path("#{@settings.export.folder}/#{File.basename(@recording.dir)}.mp4")
  end

  def take_save_answer
    state = FileDialog.state
    return if state == :closed || state == :open
    FileDialog.reset
    start_export(FileDialog.path) if state == :chosen
  end

  # The export runs in its own window; this one waits behind it, dimmed.
  # The finished video opens in the default player.
  def start_export(path)
    exporter = Exporter.new(@recording, @settings, path)
    @dimmed = true
    draw
    present
    if ExportWindow.run(exporter, @settings) == :done
      exporter.finish
      Process.wait(Process.spawn("#{Host::OPEN} #{FFmpeg.quote(path)}"))
      @status = "Exported"
    else
      exporter.cancel
      @status = "Export cancelled"
    end
    @dimmed = false
    raise_to_front
    paint_panel
  end

  def refresh_thumbnails(now)
    return if now - @last_thumbnail_check < @editor.thumbnail_refresh
    @last_thumbnail_check = now
    paint_panel if @panel.refresh_thumbnails
  end

  def playhead_time
    (@scrubbing ? @scrub_time : @player.time).clamp(0.0, @recording.duration)
  end

  def paint_panel
    @panel.paint(@player.playing?, @status, @hovered, @held)
    @panel_texture.update(@panel.canvas.pixels)
    paint_clock
  end

  def paint_clock
    @last_clock_paint = SpinelStudio.now
    @panel.paint_clock(playhead_time)
    @clock_texture.update(@panel.clock.pixels)
  end

  def draw_playhead
    x = @view.x_at(playhead_time)
    top = PREVIEW_AREA + TimelineView::RULER_TOP
    bottom = PREVIEW_AREA + TimelineView::ZOOM_TOP + TimelineView::LANE_HEIGHT
    fill(x - 1, top, 2, bottom - top, @theme.playhead)
    copy(@knob, x - KNOB / 2.0, top - KNOB / 2.0, KNOB, KNOB)
  end

  # The round grip on top of the playhead.
  def knob_texture
    size = (KNOB * scale).to_i
    canvas = Canvas.new(size, size)
    canvas.clear(0)
    canvas.circle(size / 2.0, size / 2.0, size / 2.0 - scale, @theme.playhead)
    knob = texture(size, size, true)
    knob.update(canvas.pixels)
    knob
  end

  def write_raw(path, pixels)
    file = File.open(path, "wb")
    pixels.write(file, pixels.size)
    file.close
  end
end

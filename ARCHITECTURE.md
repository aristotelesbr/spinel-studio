# Architecture

Spinel Studio follows the model of [Cap](https://github.com/CapSoftware/Cap),
the open source screen recorder, so its names and files mean what they mean
there. Nothing here is a framework of its own: plain classes, one per idea.

## A take on disk

Each recording is a project: a folder named `NAME.spinelstudio` under the
recordings folder (setting `recording.folder`), as Cap keeps its
recordings in `.cap` folders. `config/Info.plist` declares the extension
as a package, so Finder shows a project as one document and opens it with
the app. Takes from before the extension are plain folders and open the
same way (`ProjectFolder`). A project holds:

| File | Written by | What it holds |
| --- | --- | --- |
| `screen.mov` | the recorder | the screen, H.264, at the display's pixel size |
| `mouse.log` | the recorder | `time x y pressed` samples, then `end time` |
| `recording-meta.json` | the recorder | frame rate, pixel density, the picked area |
| `project-config.json` | the editor | the edits: background, cursor, camera, zoom, timeline |
| `studio.mp4` | `spinel_studio export` | the finished video (the editor saves wherever the Save panel says) |

`project-config.json` uses Cap's names: `timeline.segments` are the clips of
the recording that stay in the video (cutting splits a clip and removes a
piece), `timeline.zoomSegments` have a `start`, an `end` and an `amount`.

## Settings

`config/application.json` holds every value that tunes behavior; the app
bundle carries a copy in `Contents/Resources`.
`~/Library/Application Support/Spinel Studio/settings.json` overrides any
part of it.

| Section | What it tunes |
| --- | --- |
| `app` | the ffmpeg and ffprobe paths, the folders of macOS's cursor files, the windows' frame pace |
| `theme` | the editor's font and the dialogs' font with their weights, text sizes, corner radii, every color (CSS hex, `#RRGGBB` or `#RRGGBBAA`) |
| `toolbar` | where the bar sits, its text sizes and animation speeds |
| `recording` | frame rate, folder, countdown, codec and bitrate, the stop shortcut, the area marks (shade, outline, picker) |
| `export` | video size, codec and bitrate |
| `editor` | the timeline's rules, grab distances, undo depth, refresh intervals, scrub frames, thumbnails, keyboard shortcuts |
| `render` | when a frame is halved before scaling, the cursor spring's steps per frame |
| `project` | where a new take's `project-config.json` starts: background, cursor (motion, outline, shadow), camera, zoom |

`Settings` has one reader object per section (`settings.editor.edge_grab`);
no other code reads the JSON. A take keeps its own copy of the `project`
values, as Cap keeps cursor and camera springs per project; a take saved
before a value existed takes it from the file.

What stays in code is what is not a setting: the layout of the bar and the
editor in points (the drawing is built on it), the shapes of icons, the
cursor arrow and the hands, SDL and macOS codes, file formats and the
fixed-point arithmetic of the compositor.

## Project layout

The layout Spinel's package tool describes (`spin new`, docs/spin.md in
Spinel):

| Path | Holds |
| --- | --- |
| `bin/spinel_studio.rb` | the executable: the file Spinel compiles, with the commands (bar, record, edit, export) |
| `spinel_studio.rb` | loads the code below, in dependency order |
| `spinel_studio/` | the code, below |
| `config/application.json` | the settings |
| `config/Info.plist` | the app bundle's description for macOS |
| `native/capture.m` | the ScreenCaptureKit bridge, the only code that is not Ruby |
| `test/` | Minitest tests; `test/support/` fixtures, `test/ui/` mouse event posters for manual checks |
| `script/` | development scripts: `build`, `test`, `render_check`, `static_raise_check`, and `icon.rb` (paints the app icon) |
| `build/` | everything generated, ignored by git: the binary, the C, the native library, `Spinel Studio.app` |

There is no `spin.toml` yet: spin compiles the C (`.c`) a package carries,
and the bridge is Objective-C, so `script/build` builds the app.

## Code

`spinel_studio/` is split by what the code is about:

| Folder | Holds |
| --- | --- |
| `platform/` | the native libraries, as `ffi_func` declarations (SDL3, SDL3_ttf, CoreGraphics, the ScreenCaptureKit bridge), the ffmpeg processes, and `Window` / `Texture` / `Event` over SDL |
| `recording/` | recording a take: `RecordingSession` (idle, countdown, recording), the recorder, its meta file, the area picker and the marks of a picked area (frame, dimmed surroundings) |
| `project/` | a take as data: `Recording` (loads a take once), `ProjectConfig`, `Timeline`, `History` (undo / redo), `Span`, `ZoomPlan`, `Track` (the mouse log) |
| `render/` | making frames: `FrameComposer` (camera + compositor + cursor), used by `Exporter`, `Preview` and `ScrubStrip`; `Player` (playback over the preview); `Canvas` for antialiased drawing; `RubyGem` (the gem in the app icon) |
| `ui/` | what the windows show: `Toolbar`, `Editor` (wires the player, the timeline and the actions), `TimelinePanel` (painting), `TimelineView` (timeline geometry and gestures), `ExportWindow` (the export's progress, modal), `Button`, `Pointers` and `SystemCursor` (macOS's own hand cursors, drawn from the system's cursor PDFs with CoreGraphics), `Shortcuts`, `Theme` |

`app.rb` is the floating bar's window: it asks the `RecordingSession` to record, then opens the editor.
`native/capture.m` is the only code that is not Ruby. ScreenCaptureKit has
no C API: it takes a delegate object, Objective-C blocks, and calls back on
its own threads, which Spinel's FFI does not reach. The file only turns it
into C functions (start, newest frame, stop, screenshot); every decision is
in Ruby. Anything that has a C API, or that can be drawn, stays out of it.

## Rules

- A window is a `Window` subclass, in the shape of `Gosu::Window`: it
  overrides `update`, `draw`, `needs_redraw?` and the mouse and key hooks,
  and `show` runs the loop. Sizes are points; `Window` turns them into
  pixels.
- States and kinds are symbols (`:idle`, `:countdown`, `:recording`;
  `:seek`, `:edit`; `:clip`, `:zoom`), not numbered constants.
- Keys and buttons name the same editor actions (`:play`, `:split`,
  `:delete`, `:undo`...); `Editor#perform` carries them out.

- Native calls go through `ffi_func`; no C inside the Ruby files.
- Colors, radii and text sizes come from `Theme`; buttons are `Button`.
- What the editor and the export show is made by the same `FrameComposer`.
- Code that needs no window or native library has a Minitest test
  (`script/test`). `script/static_raise_check` fails when Spinel turned a
  call it could not resolve into a raise in the generated C.
- Generated files go to `build/`, never next to the source.

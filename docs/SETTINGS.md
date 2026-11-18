# Settings

Everything Spinel Studio can be tuned with lives in
[`config/application.json`](../config/application.json), which ships inside the
app. Each section of the file is read by a class in
[`spinel_studio/settings.rb`](../spinel_studio/settings.rb) (the `project`
section by [`project_config.rb`](../spinel_studio/project/project_config.rb)).
This page lists every key with its default and what it changes.

## Overriding a value

Create `~/Library/Application Support/Spinel Studio/settings.json` and put only
the keys you want to change in it, under the same sections:

```json
{
  "recording": { "fps": 60, "countdown": 5 },
  "editor": { "shortcuts": { "split": ["B"] } },
  "project": { "background": { "gradient": ["#0F2027", "#2C5364"] } }
}
```

How the file is applied (`Settings.load` and `Settings.merged`):

- It is laid over the defaults. Objects are merged key by key; any other value
  (a number, a string, a list) replaces the default as a whole. So
  `"gradient"` or `"zoomRange"` must be given with all of their items, while
  `"shortcuts": { "split": ["B"] }` changes only the `split` shortcut.
- If the file does not exist, the defaults are used. The file must be valid
  JSON; the code does not catch a parse error.
- The `project` section is only the starting point for a new take. Each take
  keeps its own copy in `project-config.json` inside its project folder, and
  that copy wins for that take.

Text sizes, radii and distances are in points unless a row says otherwise;
colors are CSS hex, `#RRGGBB` or `#RRGGBBAA`.

## `app`

The tools the program runs, where macOS keeps its cursors, and the frame pace of
its windows.

| Key | Default | What it changes |
| --- | --- | --- |
| `ffmpeg` | `/opt/homebrew/bin/ffmpeg` | Path of the `ffmpeg` used to encode and decode video. Set here because an app opened from Finder does not get the shell's `PATH`. |
| `ffprobe` | `/opt/homebrew/bin/ffprobe` | Path of the `ffprobe` used to read the size of a video. |
| `systemCursors` | two folders under `/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Resources/` (`cursors/macos27`, then `cursors`) | Folders searched, in order, for the macOS `openhand` and `closedhand` cursors the editor shows. When none has one, the editor falls back to SDL's pointer and move cursors. |
| `frameDelayMs` | `8` | Milliseconds the floating bar, the area picker and the export window wait between turns of their loop. |

## `theme`

The look shared by the bar, the editor and the area picker.

| Key | Default | What it changes |
| --- | --- | --- |
| `font.path` | `/System/Library/Fonts/SFNSMono.ttf` | Font file of the bar and the editor. |
| `font.weight` | `Semibold` | Named instance (weight) used from that font. |
| `dialogFont.path` | `/System/Library/Fonts/SFNS.ttf` | Font file of the export window. |
| `dialogFont.weight` | `Semibold` | Named instance (weight) used from that font. |
| `textSize` | `13` | Size of the larger text in the editor and the export window. |
| `smallTextSize` | `11` | Size of the smaller text in the editor and the export window. |
| `radius` | `8` | Corner radius of the editor's buttons and of its track lanes. |
| `largeRadius` | `10` | Read into the theme as `large_radius`; no code uses it yet. |

`theme.colors`:

| Key | Default | What it paints |
| --- | --- | --- |
| `window` | `#111114` | Background of the editor window. |
| `panel` | `#17171B` | Background of the timeline panel, the clock and the export window. |
| `surface` | `#1E1E24F2` | The floating bar's pill and the area picker's hint. |
| `lane` | `#222228` | Timeline track lanes and the export window's empty bar. |
| `well` | `#2A2A31` | Secondary buttons, the clip track's clips and the timer box in the floating bar. |
| `selected` | `#35353F` | The floating bar's selected button. |
| `edge` | `#FFFFFF2E` | The pill's outline and the outline of an unselected clip. |
| `shadow` | `#00000066` | The floating bar's drop shadow. |
| `separator` | `#FFFFFF1F` | Dividers in the floating bar. |
| `tick` | `#FFFFFF33` | The timeline ruler's tick marks. |
| `text` | `#F2F2F7` | Main text and icons. |
| `dimText` | `#F2F2F78C` | Secondary text (hints, file name, ruler times, keycaps). |
| `faintText` | `#F2F2F759` | Text and icons of disabled controls. |
| `accent` | `#7C6CF2` | Primary buttons, zoom segments and the export progress bar. |
| `accentLight` | `#9B8EFF` | A selected zoom segment. |
| `red` | `#FF453A` | The record button, the recording dot and the Delete button's text. |
| `redRing` | `#FF453A55` | The ring around the record button. |
| `outline` | `#FFFFFF` | Outline of a selected clip or zoom. |
| `hover` | `#FFFFFF1F` | Overlay on a hovered button and the keycap background. |
| `press` | `#00000024` | Overlay on a pressed button. |
| `playhead` | `#FFFFFF` | The playhead line and its handle. |
| `modalShade` | `#00000080` | Dimming over the editor while an export runs. |

## `toolbar`

The floating recording bar.

| Key | Default | What it changes |
| --- | --- | --- |
| `bottomGap` | `80` | Distance between the bar and the bottom of the screen. |
| `timerTextSize` | `15` | Size of the recording timer's text. |
| `countdownTextSize` | `22` | Size of the countdown's numbers. |
| `hoverFadeSpeed` | `9.0` | How fast a button's hover highlight fades in and out (share of the full level per second). |
| `pulseSpeed` | `5.0` | Speed of the pulsing red dot and record icon: the multiplier of time inside the sine that drives the pulse. |
| `pressedIconScale` | `0.88` | Scale of a button's icon while it is held down. |
| `hideWaitMs` | `200` | Milliseconds the bar waits after hiding, before the area picker captures the screen. |

## `recording`

The take: how it is captured and encoded, and the marks of a picked area.

| Key | Default | What it changes |
| --- | --- | --- |
| `fps` | `30` | Frames per second of the recording. |
| `folder` | `~/Movies/Spinel Studio` | Where new takes are saved (created when missing), and the folder the bar's open panel starts in. |
| `projectExtension` | `spinelstudio` | Extension of a take's project folder. |
| `countdown` | `3` | Seconds counted down before a take starts. |
| `codec` | `h264_videotoolbox` | ffmpeg video codec (`-c:v`) of the recording. |
| `bitrate` | `30M` | ffmpeg video bitrate (`-b:v`) of the recording. |
| `captureStartTimeout` | `3.0` | Seconds to wait for the screen capture's first frame. |
| `stopShortcut` | `Ctrl+Option+S` | Keys that stop a recording, held together, anywhere on screen. Parts are joined with `+`: `Ctrl`, `Option`, `Shift`, `Cmd`, a letter, a digit, `Escape` or `Space`. |

`recording.area`, for recording a part of the screen:

| Key | Default | What it changes |
| --- | --- | --- |
| `smallest` | `40` | Smallest size of a picked area, in screen pixels. |
| `pickerShade` | `#00000078` | Dimming over the frozen screen while an area is picked. |
| `shade` | `#0000004D` | Dimming over the part of the screen outside the recorded area. |
| `outline` | `#FFFFFF` | Color of the line around the area. |
| `halo` | `#0000008C` | Color of the dark halo beside that line. |

## `export`

| Key | Default | What it changes |
| --- | --- | --- |
| `folder` | `~/Movies/Spinel Studio` | Folder the Save panel suggests for the exported video. |
| `width` | `1920` | Width in pixels of the exported video, and of the editor's preview. |
| `height` | `1080` | Height in pixels of the exported video, and of the editor's preview. |
| `codec` | `h264_videotoolbox` | ffmpeg video codec (`-c:v`) of the exported video. |
| `bitrate` | `16M` | ffmpeg video bitrate (`-b:v`) of the exported video. |

## `editor`

The timeline's rules, how close the pointer must be to grab something, how often
the panel refreshes, and the keyboard shortcuts.

| Key | Default | What it changes |
| --- | --- | --- |
| `frameDelayMs` | `4` | Milliseconds the editor waits between turns of its loop. |
| `shortestClip` | `0.3` | Shortest length in seconds of a clip or zoom; it limits dragging an edge and splitting. |
| `newZoomLength` | `2.0` | Length in seconds of a new zoom, at most the free space where it is made. |
| `zoomStep` | `0.25` | How much the selected zoom's amount changes with the zoom in and zoom out shortcuts and buttons. |
| `zoomRange` | `[1.25, 3.0]` | Smallest and largest amount a zoom can be given. |
| `edgeGrab` | `6` | Distance within which the pointer grabs the edge of a clip or zoom. |
| `playheadGrab` | `8` | Distance within which the pointer grabs the playhead. |
| `historyLimit` | `100` | How many edits undo remembers. |
| `clockRefresh` | `0.05` | Fewest seconds between repaints of the time display during playback and scrubbing. |
| `thumbnailRefresh` | `0.5` | Seconds between checks for newly written clip thumbnails. |
| `exportSlice` | `0.1` | Seconds the export works before the export window draws again. |
| `progressStep` | `0.01` | How much the export's progress (0 to 1) must grow before the window redraws. |
| `catchUp` | `0.2` | How many seconds playback may fall behind before it drops the lost time instead of rushing to catch up. |
| `scrubPreview` | `[960, 540]` | Width and height in pixels of the preview frames shown while dragging the playhead. |
| `thumbnails.width` | `480` | Width in pixels of the small frames ffmpeg writes in the background for scrubbing and thumbnails. |
| `thumbnails.fps` | `6` | Frames per second of those small frames. |
| `thumbnails.tileWidth` | `52` | Width of one thumbnail tile in the clip track. |

`editor.shortcuts` maps an action to a list of keys; the first key of an action
is the one its button shows. Keys are written like `S`, `Backspace` or
`Shift+Cmd+Z`: the key name is SDL's, and the modifiers are `Cmd`, `Ctrl`
(both mean Cmd or Ctrl), `Shift` and `Option`.

| Action | Default | What it does |
| --- | --- | --- |
| `play` | `Space` | Plays or pauses. |
| `split` | `S` | Splits the clip at the playhead. |
| `delete` | `Backspace`, `Delete` | Deletes the selected clip or zoom. |
| `zoomIn` | `Up` | Makes the selected zoom larger by `zoomStep`. |
| `zoomOut` | `Down` | Makes the selected zoom smaller by `zoomStep`. |
| `undo` | `Cmd+Z` | Undoes the last edit. |
| `redo` | `Shift+Cmd+Z` | Redoes it. |
| `save` | `Cmd+S` | Saves the project and shows "Saved". |
| `cancel` | `Escape` | Cancels a running export. |

## `render`

How frames are made, for the preview and the export.

| Key | Default | What it changes |
| --- | --- | --- |
| `halveBelow` | `1.5` | When the zoomed crop is more than this many times the size of its window, the frame is first halved by averaging, then sampled. |
| `cursorStepsPerFrame` | `4` | How many times per frame the cursor's spring is stepped, so it stays stable. |

## `project`

The starting point for a new take; each take then keeps its own copy in
`project-config.json`. A take saved before a setting existed takes the value
from these defaults.

`project.background`, the wallpaper behind the recording. Sizes are for a
1080-pixel-high video and scale with the export height.

| Key | Default | What it changes |
| --- | --- | --- |
| `padding` | `90` | Margin between the video and the edge of the wallpaper. |
| `rounding` | `22` | Corner radius of the recording. |
| `shadow` | `0.55` | Strength of the recording's drop shadow (0 is none). |
| `shadowBlur` | `60` | How far the shadow spreads. |
| `shadowOffset` | `24` | How far the shadow is moved down. |
| `gradient` | `["#3B2A8F", "#E25C8C"]` | The wallpaper's two colors, from the top left corner to the bottom right. |

`project.cursor`, the drawn cursor.

| Key | Default | What it changes |
| --- | --- | --- |
| `size` | `80` | Height of the cursor arrow in screen pixels. |
| `smoothing` | `11.0` | Stiffness of the spring that smooths the cursor's path; lower is smoother. |
| `clickGrip` | `4.0` | Factor the spring's stiffness is multiplied by around a click. |
| `clickWindow` | `[0.15, 0.3]` | Seconds before and after a click during which the spring is tighter. |
| `clickDip` | `0.22` | How much smaller the arrow gets on a click (share of its size). |
| `clickDipLength` | `0.25` | Seconds the arrow takes to dip and come back. |
| `outline` | `7.0` | Width of the arrow's white outline, in pixels of a 120-pixel arrow. |
| `shadowBlur` | `14.0` | Blur of the arrow's shadow, in pixels of a 120-pixel arrow. |
| `shadowOffset` | `6.0` | Offset of the arrow's shadow, in pixels of a 120-pixel arrow. |
| `shadowOpacity` | `0.45` | Opacity of the arrow's shadow. |

`project.camera`, the zoomed view following the cursor.

| Key | Default | What it changes |
| --- | --- | --- |
| `follow` | `5.0` | Stiffness of the pan spring; higher follows the cursor more closely. |
| `comfort` | `0.5` | Share of the view the cursor can roam in without the view panning. |

`project.zoom`, zooms made automatically from clicks, and the amount of a new zoom.

| Key | Default | What it changes |
| --- | --- | --- |
| `amount` | `2.0` | Magnification of a new zoom, including the ones made from clicks. |
| `ramp` | `0.5` | Seconds a zoom takes to ease in and out. |
| `lead` | `0.5` | Seconds before a click at which its zoom is fully in. |
| `hold` | `1.8` | Seconds a zoom is held after the last click. |
| `joinWithin` | `2.0` | Clicks within this many seconds of each other make one zoom. |

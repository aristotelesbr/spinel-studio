# Changelog

All notable changes to Spinel Studio are written here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions
follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.1] - 2026-11-20

### Added

- GitHub Actions builds the app with the Spinel revision in
  `.spinel-revision` and exports a take with it, for every push and pull
  request.
- Pushing a version tag publishes the release: `script/release` prepares
  it and the Release workflow builds the app and writes the notes.

### Fixed

- The released app opens on macOS 14 and newer. The 0.1.0 and 0.2.0
  builds asked for macOS 27, the system they were built on.

## [0.2.0] - 2026-11-20

### Added

- Cmd+E exports from the editor, and the Export button shows the shortcut.
- The export window shows the time left once the export has run a few
  seconds (`editor.timeLeftAfter`).
- `docs/SETTINGS.md` lists every setting with its default and what it
  changes.
- GitHub Actions runs the Minitest suite on macOS for every push and pull
  request.
- A contributing guide and a pull request template.

## [0.1.0] - 2026-11-15

The first release: a screen recorder for macOS written in Ruby and compiled
by Spinel.

### Added

- A floating bar to record the whole display or a picked area, with a
  countdown and a stop shortcut (Control+Option+S). The bar and the marks
  around the area stay out of the video.
- Recording with ScreenCaptureKit, with the mouse logged beside the video.
- Frames composed in Spinel: a gradient wallpaper, padding, rounded
  corners, a soft shadow, a larger cursor smoothed by a spring that dips on
  each click, and zooms that follow the clicks.
- An editor with a Video track (split, trim, delete) and a Zoom track (add,
  move, resize, amount), undo and redo, and keyboard shortcuts.
- Export to MP4 at 1920×1080 with the system's Save panel and a progress
  window that can cancel.
- Projects: every take is a `.spinelstudio` document that saves as you
  edit and reopens from Finder or from the bar's folder button.
- Every setting in `config/application.json`, overridable in the user's
  `settings.json`.

[Unreleased]: https://github.com/aristotelesbr/spinel-studio/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/aristotelesbr/spinel-studio/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/aristotelesbr/spinel-studio/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/aristotelesbr/spinel-studio/releases/tag/v0.1.0

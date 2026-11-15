# Changelog

All notable changes to Spinel Studio are written here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions
follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/aristotelesbr/spinel-studio/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/aristotelesbr/spinel-studio/releases/tag/v0.1.0

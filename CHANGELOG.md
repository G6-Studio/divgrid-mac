# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Unit tests for grid geometry, screen coordinate conversion, shortcuts and preferences.
- Structured logging through `os.Logger` (`subsystem == "studio.g6.divgrid"`).
- App icon.
- "Grant Accessibility Access…" menu item shown while permission is missing.

### Changed
- Split pure logic into a `DivGridCore` library; split the app into focused controllers.
- Target window tracking uses Accessibility notifications instead of polling.
- Failures moving or resizing a window are now logged instead of ignored.
- Built with the Swift 6 language mode.

## [0.1.0]

### Added
- Hotkey and menu bar icon open a drag-to-select grid on every display.
- Target window header and outline; retargets when you click another window or app.
- Settings: shortcut, grid size, margin, launch at login.

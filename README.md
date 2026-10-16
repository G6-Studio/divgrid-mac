# DivGrid

A small, native macOS window manager built around one idea: press a hotkey, drag across a grid, and the
frontmost window snaps to exactly that region.

Runs natively on Apple silicon (arm64). No Rosetta.

> DivGrid is an independent project. It is not affiliated with or endorsed by the makers of any other
> window-management app.

## Features

- Global hotkey (default **⌃⌥Space**) or a left click on the menu bar icon shows the grid.
- Drag across any rectangle of cells to place the target window there.
- The grid appears on every display; choosing cells on a display moves the window to that display.
- The grid shows which window will be resized (app icon, name, title, and an outline around the window).
  Click another window or app while the grid is open to retarget it.
- Settings: custom hotkey, rows and columns (2–20), margin, launch at login.
- Right click (or control click) the menu bar icon for Settings and Quit.

## Download

Grab the latest `DivGrid-<version>.zip` from the [Releases](../../releases) page, unzip it, and move
`DivGrid.app` to `/Applications`. Each release includes a SHA-256 checksum.

## Requirements

- macOS 26 or later, Apple silicon
- Xcode 26+ / Swift 6.2+ toolchain to build

## Build and run

```sh
./scripts/build-app.sh
open build/DivGrid.app
```

The script builds an arm64 release binary and assembles `build/DivGrid.app`. It signs ad hoc by default;
set `SIGN_IDENTITY` to use a real certificate:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/build-app.sh
```

## Permissions

DivGrid needs **Accessibility** access to move and resize other apps' windows. Grant it in
System Settings → Privacy & Security → Accessibility when prompted. DivGrid does not collect or transmit
any data.

## Project layout

| Path | Purpose |
|---|---|
| `Sources/DivGrid/AppDelegate.swift` | Menu bar item, grid panels, target tracking |
| `Sources/DivGrid/GridPanel.swift` | Grid UI (SwiftUI) and the target outline |
| `Sources/DivGrid/WindowMover.swift` | Accessibility API window lookup and placement |
| `Sources/DivGrid/HotKey.swift` | Global hotkey (Carbon) |
| `Sources/DivGrid/Settings*.swift` | Preferences and the settings window |
| `scripts/build-app.sh` | Builds the `.app` bundle |

## Support

DivGrid is free and open source. If it's useful to you, you can support development on Patreon
(use the **Sponsor** button on the GitHub repository).

## Roadmap

- Saved-region shortcuts
- Mac App Store build
- Possible Windows and Linux (GNOME/KDE) versions, as separate native apps

## Releasing

Pushing a tag like `v0.2.0` runs `.github/workflows/release.yml`, which builds, signs, notarizes (when the
signing secrets are configured), and publishes a GitHub release. To package locally:

```sh
SIGN_IDENTITY="Developer ID Application: ..." NOTARY_PROFILE="my-notary-profile" ./scripts/package-release.sh
```

## License

[MIT](LICENSE), © G6 Studio LLC. Developed by Jodakila Galang.

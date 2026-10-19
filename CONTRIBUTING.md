# Contributing to DivGrid

Thanks for your interest! Bug reports, ideas and pull requests are welcome.

## Setup

You need macOS 26+ on Apple silicon and the Xcode 26+ command line tools.

```sh
swift build            # compile
swift test             # run the unit tests
./scripts/build-app.sh # assemble build/DivGrid.app
```

Grant the built app Accessibility permission (System Settings → Privacy & Security → Accessibility) to try it.

## Code layout

- `Sources/DivGridCore` holds the pure logic: grid geometry, screen coordinates, shortcuts and preferences. It must
  not import AppKit, so it stays easy to test. New logic that can live here should, with tests in
  `Tests/DivGridCoreTests`.
- `Sources/DivGrid` is the app: windows, menu bar, hotkey and Accessibility API glue.

## Before opening a pull request

- `swift test` passes.
- `swift format -i -r Sources Tests` has been run (CI runs `swift format lint --strict`).
- User-visible changes are noted in `CHANGELOG.md` under "Unreleased".
- Keep pull requests focused; explain the *why* in the description.

## Debugging

DivGrid logs through `os.Logger`. Stream the logs while using the app:

```sh
log stream --predicate 'subsystem == "studio.g6.divgrid"' --level debug
```

## Reporting security issues

See [SECURITY.md](SECURITY.md).

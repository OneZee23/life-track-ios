# LifeTrackTests

Unit tests for the Reflection engine (and future test code).

## Status

These files exist but are **not yet wired into an Xcode test target**. The
`feature/v0.6.0` agent-driven implementation chose to defer the test-target
creation (it requires Xcode UI manipulation that's risky to script).

## To wire up

1. Open `LifeTrack.xcodeproj` in Xcode.
2. File → New → Target → iOS → Unit Testing Bundle.
3. Product Name: `LifeTrackTests`. Target to be Tested: `LifeTrack`. Language: Swift.
4. Drag `ReflectionEngineTests.swift` and `Helpers/ReflectionTestHelpers.swift` into the new target. Make sure target membership is `LifeTrackTests` only.
5. Run with `Cmd+U`.

## What's covered

15 tests for `ReflectionEngine`:

- 7 drift cases (brand-new habit, 3-day gap fires, 1-day no-fire, 11-day no-fire, weekend skipper, cooldown, archived)
- 4 weekly cases (zero days, seven days, outside window, mid-week-created habit)
- 1 no-active-habits guard
- 1 priority test (drift beats weekly)
- 1 today-already-shown
- 1 master-toggle-off

If `computeWeeklySummary` (Task 5) and `computeDrift` (Task 6) implementations
are correct, all 15 should pass once the target is wired.

# Menu Bar Gauge Icon Design

## Context

The current menu bar icon uses two horizontal bars and reads as visually weak at macOS status bar size. We want a cleaner, more polished icon while preserving quick usage-at-a-glance behavior.

## Goal

Replace the current bar icon with a circular gauge style that remains legible at small sizes and still communicates both short-window and weekly usage.

## Chosen Approach

- Use a template monochrome icon so the system controls final color in light/dark menu bar contexts.
- Render two concentric progress rings:
  - Outer ring = weekly usage.
  - Inner ring = short-window usage.
- Start arcs from top-center with a small visual gap to avoid a flat full-circle look.
- Keep stale-state signaling by lowering contrast through existing `secondaryLabelColor` usage.
- Keep icon size and call sites unchanged (`IconRenderer().makeImage(for:)`) to minimize risk.

## Impact

- Improves visual quality and recognizability in the menu bar.
- Preserves existing model inputs and state mapping logic.
- Maintains compatibility with current stale behavior and update flow.
- Limits scope to icon rendering and icon-specific tests.

## Verification

- Run `swift test` and `swift build`.
- Launch app and verify the icon remains legible in the menu bar.
- Confirm both progress values visibly affect different rings.
- Confirm stale state still renders with reduced emphasis.

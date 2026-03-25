# Settings Width Design

## Context

The Settings window currently opens at `440x230`, which feels wider than needed for the current controls (`Refresh Interval`, `Launch at login`, `Logout`).

## Goal

Make the Settings window visually tighter while keeping all controls readable, and ensure the main menu window opens already focused.

## Chosen Approach

- Change Settings window width from `440` to `380`.
- Keep height at `230`.
- Keep the same minimum size as the initial size (`380x230`) to preserve a stable layout.
- When showing the main popover window, activate the app first and promote the popover window to key state.
- Do not change menu popover dimensions or Settings view internals.

## Impact

- More compact Settings presentation.
- Better interaction flow because the main popover is immediately focused.
- No changes to auth, refresh logic, or core behavior.
- Low-risk UI-only adjustment in the app shell.

## Verification

- Run `swift test` and `swift build`.
- Open Settings from menu bar and confirm controls fit without clipping at `380px` width.
- Confirm the main popover is focused (ready for interaction) when opened.

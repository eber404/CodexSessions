# Codex Watch

Codex Watch is a lightweight macOS menu bar app that shows OpenAI Codex usage windows at a glance.

## What the app does

- Shows usage as percent for short and weekly windows.
- Keeps status visible from the menu bar icon.
- Opens a compact popover with usage details and refresh timestamp.
- Provides a small Settings screen for refresh interval and launch-at-login.

## Authentication model

Codex Watch resolves auth in this order:

1. Local auth files (Codex/OpenCode)
2. OpenAI OAuth fallback

Common local auth locations:

- `~/.codex/auth.json`
- `$CODEX_HOME/auth.json`
- `~/.config/opencode/auth.json`
- `$OPENCODE_HOME/auth.json`

In the UI, the app labels the active connection source (for example, OpenCode, Codex CLI, or OpenAI OAuth).

## Refresh behavior

- Supports refresh interval presets: 1, 3, and 5 minutes.
- Keeps last known snapshot on transient failures.
- Exposes explicit manual refresh in the menu.
- Stores user-selected refresh interval and launch-at-login preference across app restarts.

## Security and data handling

- App-managed OAuth credentials are stored in macOS Keychain.
- Auth/token handling is isolated to core auth components.
- Never store or commit raw tokens in source control.

## Releases

Installable binaries are published in GitHub Releases.

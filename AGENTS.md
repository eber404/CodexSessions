# Codex Watch - AGENTS

## Vision

Codex Watch is a lightweight macOS menu bar app that shows OpenAI Codex usage windows at a glance.
The app prioritizes fast visual feedback and minimal setup.

## Scope

- Single-provider focus: OpenAI Codex usage.
- Menu bar first UX (no complex dashboard in v1).
- Auth priority order:
  1. Local auth files (Codex/OpenCode)
  2. Codex-compatible OpenAI OAuth fallback

## Product behavior

- Show usage as percentage (0% to 100%) for short and weekly windows.
- Keep menu actions simple, full-width, and quick to scan.
- Show Signin action only when user is effectively logged out.
- Keep refresh explicit and immediate from the menu (`Updated at` + refresh icon).
- Keep Settings compact and focused on essentials.
- Offer refresh interval presets of 1, 3, and 5 minutes.
- Keep logout in Settings, not in the main menu action list.
- Session Keep-Alive: configurable ping to keep Codex sessions active. User sets hour/minute schedule in Settings; pings fire every 5 hours starting from next interval.
- Session Keep-Alive should use Codex session-aligned auth flow, avoid duplicate background loops, and resolve a fresh token for each ping.

## High-level architecture

- `CodexWatchCore`
  - Auth source discovery
  - Access token resolution and refresh handling
  - Usage request and parsing (`/backend-api/wham/usage`)
  - Refresh coordination and state modeling

- `CodexWatch` executable target
  - App lifecycle and menu bar wiring
  - Menu content and settings UI
  - OAuth interaction flow

## Reliability priorities

- Keep last known usage snapshot on transient failures.
- Treat API schema changes as parser responsibilities, not UI failures.
- Force real refresh requests (avoid stale cached responses).
- Keep updated timestamp in sync with manual and interval refreshes.

## Security posture

- Never commit tokens or copied cookie headers.
- Store app-managed OAuth credentials in macOS Keychain.
- Keep credentials handling isolated in core auth components.
- Prefer logout behavior that clears in-app auth state immediately.

## Developer workflow

- Use tests as the guardrail for parser/auth behavior.
- Keep UI simple and focused on quick status read.
- Favor incremental, low-risk changes to auth and parsing paths.
- Validate with `swift test` and `swift build` before closing work.

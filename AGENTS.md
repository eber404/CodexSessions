# CodexSessions - AGENTS

## Vision

CodexSessions is a lightweight macOS menu bar app that shows OpenAI Codex usage windows at a glance.
The app prioritizes fast visual feedback and minimal setup.

## Scope

- Single-provider focus: OpenAI Codex usage.
- Menu bar first UX (no complex dashboard in v1).
- Auth priority order:
  1. Local auth files (Codex/OpenCode)
  2. In-app OpenAI OAuth fallback

## High-level architecture

- `CodexUsageCore`
  - Auth source discovery
  - Access token resolution and refresh handling
  - Usage request and parsing (`/backend-api/wham/usage`)
  - Refresh coordination and state modeling

- `CodexSessions` executable target
  - App lifecycle and menu bar wiring
  - Menu content and settings UI
  - OAuth interaction flow

## Reliability priorities

- Keep last known usage snapshot on transient failures.
- Treat API schema changes as parser responsibilities, not UI failures.
- Prefer explicit source labeling (`local auth` vs `oauth`).

## Security posture

- Never commit tokens or copied cookie headers.
- Store app-managed OAuth credentials in macOS Keychain.
- Keep credentials handling isolated in core auth components.

## Developer workflow

- Use tests as the guardrail for parser/auth behavior.
- Keep UI simple and focused on quick status read.
- Favor incremental, low-risk changes to auth and parsing paths.

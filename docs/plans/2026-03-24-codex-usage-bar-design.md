# Codex Usage Bar Design

## Goal

Build a simple macOS menu bar app that shows Codex usage in the menu bar and supports two auth sources:

- automatic discovery of local Codex/OpenAI auth when available
- native OpenAI OAuth fallback when local auth is unavailable

The app targets a Codex-only V1 and reads usage from `https://chatgpt.com/backend-api/wham/usage`.

## Product scope

- macOS 14+
- menu bar only app, no Dock icon
- short-window + weekly usage display
- source label showing whether data comes from local auth or in-app OAuth
- manual refresh + periodic refresh
- launch at login option
- settings window for auth and refresh behavior

## Non-goals for V1

- browser cookie import
- multi-provider support
- historical charts or breakdown tables
- widgets
- billing or credits purchase flows

## Architecture

The app is split into a testable core module and a thin app module.

- `CodexUsageCore` holds auth discovery, OAuth persistence, request building, endpoint parsing, refresh logic, and view models.
- `CodexUsageBar` owns the menu bar status item, SwiftUI views, app lifecycle, and settings window.

This keeps the logic testable without UI bootstrapping and lets the app layer stay mostly declarative.

## Auth strategy

The app tries auth in this order:

1. custom auth file path if configured
2. default local auth paths if found
3. stored in-app OAuth credentials in Keychain

If none are available, the menu prompts the user to connect with OpenAI.

The app never stores copied browser cookies or hard-coded bearer tokens in source control.

## Data flow

1. App launches and creates a refresh coordinator.
2. Coordinator resolves the active auth source.
3. `UsageClient` calls the usage endpoint.
4. The response is parsed into a normalized snapshot.
5. UI renders the short window and weekly window from the snapshot.
6. Failures preserve the last known snapshot and mark the UI stale.

## UI direction

The interface borrows the fast-read spirit of CodexBar but stays simpler.

- menu bar icon: two horizontal bars
- primary menu card: account, source, last updated, short window, weekly window
- actions: refresh, open settings, connect/disconnect auth, quit
- settings: auth source, OAuth connect/disconnect, refresh interval, launch at login, used vs remaining display

## Error handling

- `401` or `403`: auth expired or missing
- `429`: rate limited, keep prior snapshot and show stale badge
- `5xx`: service unavailable, keep prior snapshot
- parse failure: show schema error state without crashing
- offline: show last successful snapshot with stale messaging

## Testing strategy

- parser tests with fixture JSON
- auth source resolution tests
- refresh coordinator tests using stubbed client responses
- request builder tests to ensure the endpoint and required headers are correct
- smoke verification by building and launching the app locally

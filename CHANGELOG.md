# Changelog

All notable changes to Codex Watch are documented in this file.

## [Unreleased]

### Added
- Session Keep-Alive feature: configurable ping to keep Codex sessions active
  - Toggle to enable/disable in Settings
  - Hour slider (0-23h) and minute slider (0, 5, 10...55) to set session schedule reference
  - Visual timeline showing 5h session intervals based on selected schedule
  - 5-hour interval pings via Chat Completions API
  - Pings start at next 5h interval from current time (not at configured time if already passed)

### Changed
- Settings UI now includes Session Keep-Alive configuration section

## [1.0.3] - 2026-03-25

### Fixed
- Added token expiration detection for local auth files - now automatically falls back to OpenCode or OAuth when Codex CLI token is expired.
- Fixed infinite loading state when no valid auth is available - now shows sign-in button instead.

## [1.0.2] - 2026-03-25

### Fixed
- Fixed Codex CLI auth file parsing to recognize `tokens.access_token` structure.

## [1.0.1] - 2026-03-25

### Added
- Persisted user settings for refresh interval and launch-at-login across app restarts.
- Added app-level tests for settings persistence behavior.
- Added automatic fallback from local auth (Codex CLI/OpenCode) to OpenAI OAuth when local auth returns unauthorized.

### Changed
- README rewritten to focus on product behavior and release usage instead of local run instructions.
- Settings screen now writes refresh interval and launch-at-login through `AppModel` as the source of truth.

### Fixed
- Reduced false "auth source conflict" cases by switching to OAuth automatically when local auth is stale.

## [1.0.0] - 2026-03-25

### Added
- Initial stable release of Codex Watch menu bar app for OpenAI Codex usage visibility.
- Source-aware auth status labels (OpenCode, Codex CLI, OpenAI OAuth).
- Default-browser OAuth flow with localhost callback handling.
- Animated gauge-style menu bar icon during refresh.
- Signed-out loading state, improved logout flow, and compact settings window.

### Changed
- Improved refresh timestamp handling and refresh coordination behavior.
- Updated menu and settings layout for faster scanning and cleaner actions.

### Security
- OAuth credentials stored in macOS Keychain.

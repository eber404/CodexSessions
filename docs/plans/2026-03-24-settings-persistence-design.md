# Settings Persistence Design

## Goal

Persist and restore user preferences for refresh interval and launch-at-login across app restarts.

## Chosen Approach

- Keep persistence centralized in `AppModel` as the single source of truth.
- Use `UserDefaults` with explicit keys for:
  - `refreshIntervalSeconds`
  - `launchAtLoginEnabled`
- Load persisted values during app startup (`AppModel.start()`) before refresh scheduling.
- Apply launch-at-login state at startup through `LoginItemManager`.
- Persist changes immediately when users update settings.

## Scope

- Includes refresh interval persistence.
- Includes launch-at-login persistence.
- No additional settings persistence in this change.

## Verification

- Add tests for reading/writing persisted settings in model logic.
- Run `swift test` and `swift build`.
- Manual check: set both values, close app, reopen, confirm values are restored.

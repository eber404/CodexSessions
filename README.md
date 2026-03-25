# CodexSessions

Simple macOS menu bar app that shows Codex usage (short window + weekly window) from OpenAI's usage endpoint.

## Features (V1)

- Menu bar icon with two bars (short + weekly)
- Popover with current usage, reset time, source label, and refresh action
- Auto-detect local auth from:
  - `~/.codex/auth.json`
  - `$CODEX_HOME/auth.json`
  - `~/.config/opencode/auth.json`
  - `$OPENCODE_HOME/auth.json`
- OAuth fallback using in-app flow (experimental)
- Manual token save to Keychain fallback
- Refresh loop and launch-at-login toggle

## Build

```bash
swift build
```

## Test

```bash
swift test
```

## Run

```bash
swift run CodexSessions
```

## Hot Reload (InjectionIII)

- Install app: `/Applications/InjectionIII.app` (version `5.1.0` installed locally).
- Debug builds load `macOSInjection.bundle` when the InjectionIII app is running.
- Debug linker flags already include `-Xlinker -interposable`.
- In Xcode 16.3+, add `EMIT_FRONTEND_COMMAND_LINES=YES` in Debug build settings.

## OAuth notes

The OAuth flow is optional and experimental. To enable it, set:

```bash
export OPENAI_OAUTH_CLIENT_ID="your_client_id"
export OPENAI_OAUTH_REDIRECT_URI="codexusagebar://oauth/callback"
```

If OAuth is not configured, you can still use auto-discovered local auth or save a manual access token from Settings.

## Security

- Do not hard-code bearer tokens in source files.
- Tokens are stored in macOS Keychain (`CodexSessions` service).

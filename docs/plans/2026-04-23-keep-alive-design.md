# Keep-Alive Fix Design

## Goal

Make Session Keep-Alive actually keep Codex session alive by pinging Codex-aligned endpoint, preventing duplicate background tasks, and exposing enough response detail to debug failures.

## Current Problems

1. `AppModel.startSessionKeepAlive()` replaces `sessionKeepAlive` instance without stopping old actor task first.
2. Keep-alive uses `https://api.openai.com/v1/chat/completions`, which does not match Codex usage flow built around `chatgpt.com` session-backed auth.
3. Ping failures collapse into generic `serverError`, hiding HTTP status and response body.
4. Ping loop captures one token at startup and can keep using stale token for later intervals.

## Chosen Approach

Use dedicated keep-alive client for Codex session endpoint on `chatgpt.com`, resolve fresh token before each ping, and stop any previous keep-alive actor before starting new one.

## Alternatives Considered

### 1. Keep Chat Completions endpoint, fix lifecycle and logging only

Rejected. This explains duplicate logs, but not why feature should preserve Codex session specifically.

### 2. Disable keep-alive until endpoint proven

Rejected for now. Safe fallback, but leaves feature broken instead of fixing root cause.

### 3. Chosen: Codex session endpoint + lifecycle fix + diagnostics

Accepted. Best match for product intent and observed auth model.

## Design

### Lifecycle

- `AppModel.startSessionKeepAlive()` must stop old actor before nil/replacement.
- `stopSessionKeepAlive()` remains single shutdown path.
- Settings changes that restart keep-alive should not accumulate tasks.

### Ping Flow

- Replace `ChatCompletionClient` use in keep-alive path with client that targets Codex session-backed endpoint.
- `SessionKeepAlive` should no longer hold raw access token for full task lifetime.
- Instead, keep-alive loop should ask injected token provider for fresh token each time it pings.

### Error Reporting

- Keep distinct errors for `unauthorized`, `rateLimited`, `serverError(statusCode: Int, bodySnippet: String?)`, `invalidResponse(statusCode: Int, bodySnippet: String?)`.
- Log exact status code and short response snippet for non-200 responses.
- Preserve terse runtime logging, but make it actually diagnostic.

### Scheduling

- Keep current scheduling behavior: first ping at next 5-hour interval from configured reference time, then every 5 hours.
- This change focuses on correctness, not UX semantics.

## Testing Strategy

1. Add regression test proving restart does not leave old keep-alive task running.
2. Add test proving keep-alive client targets Codex-aligned endpoint, not chat completions.
3. Add test proving non-200 response exposes status/body detail.
4. Run targeted core tests first, then full `swift test`.

## Non-Goals

- No schedule UX redesign.
- No auth source redesign.
- No commit in this step unless explicitly requested.

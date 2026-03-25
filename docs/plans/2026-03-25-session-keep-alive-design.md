# Session Keep-Alive Design

## Overview

Add a background keep-alive mechanism that sends "oi" via Chat Completions API every 5 hours to maintain active Codex sessions.

## Motivation

Prevent session windows from expiring due to inactivity. The existing app only monitors usage but doesn't interact with the API to keep sessions alive.

## Architecture

```
AppModel
├── RefreshCoordinator (usage: 1-5 min intervals)
│   └── UsageClient → /backend-api/wham/usage
└── SessionKeepAlive (5 hours)
    └── ChatCompletionClient → /v1/chat/completions
```

Both keep-alive components share the same `AccessTokenProvider` to reuse existing auth.

## Components

### 1. ChatCompletionModels

**File:** `Sources/CodexUsageCore/Networking/ChatCompletionModels.swift` (new)

```swift
public struct ChatCompletionRequest: Codable {
    public let model: String
    public let messages: [Message]
    public struct Message: Codable {
        public let role: String
        public let content: String
    }
    public init(model: String = "gpt-4o", messages: [Message]) {
        self.model = model
        self.messages = messages
    }
}

public struct ChatCompletionResponse: Codable {
    public let id: String?
    public let choices: [Choice]?
    public struct Choice: Codable {
        public let message: Message?
        public let finishReason: String?
    }
}
```

### 2. ChatCompletionClient

**File:** `Sources/CodexUsageCore/Networking/ChatCompletionClient.swift` (new)

- Wraps existing `URLSessionHTTPClient`
- Uses same `AccessTokenProvider` as UsageClient
- Endpoint: `https://api.openai.com/v1/chat/completions`
- Method: POST
- Sends minimal request with "oi" message
- Returns void on success, throws on failure

### 3. SessionKeepAlive

**File:** `Sources/CodexUsageCore/Refresh/SessionKeepAlive.swift` (new)

- Task-based scheduler using `Task.sleep`
- Fixed 5-hour interval (5 * 60 * 60 = 18000 seconds)
- Fire-and-forget: ignores response, logs errors to console
- Does not affect UI state
- Starts after auth resolution in AppModel

## Integration

### AppModel changes

```swift
// New property
private var sessionKeepAlive: SessionKeepAlive?

// In start()
func start() {
    restoreUserSettings()
    rebuildServiceAndRefresh()
    startSessionKeepAlive()
}

// New method
private func startSessionKeepAlive() {
    guard !isSignedOut else { return }
    let tokenProvider = AccessTokenProvider(tokenStore: tokenStore, refresher: oauthSession)
    let client = ChatCompletionClient(tokenProvider: tokenProvider)
    sessionKeepAlive = SessionKeepAlive(client: client)
    sessionKeepAlive?.start()
}
```

### Error Handling

- Network failures: logged to console, no UI impact
- Auth failures: logged, keep-alive stops
- No user-facing error messages

## Testing

- `ChatCompletionClientTests`: Mock HTTP, verify request body, status 200
- `SessionKeepAliveTests`: Verify ping fires at correct interval (mocked time)

## Constraints

- Interval is hardcoded (5 hours) - not configurable
- No retry logic on failure
- No queuing if device is offline

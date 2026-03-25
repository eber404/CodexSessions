# Session Keep-Alive Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add background keep-alive that sends "oi" via Chat Completions API every 5 hours to maintain active Codex sessions.

**Architecture:** New ChatCompletionClient reuses existing AccessTokenProvider. SessionKeepAlive schedules pings every 5 hours. Both integrated into AppModel.

**Tech Stack:** Swift, URLSession, existing CodexUsageCore components

---

## Task 1: ChatCompletionModels

**Files:**
- Create: `Sources/CodexUsageCore/Networking/ChatCompletionModels.swift`
- Test: `Tests/CodexUsageCoreTests/ChatCompletionModelsTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/CodexUsageCoreTests/ChatCompletionModelsTests.swift
import XCTest
@testable import CodexUsageCore

final class ChatCompletionModelsTests: XCTestCase {
    func testRequestEncoding() {
        let request = ChatCompletionRequest(
            messages: [ChatCompletionRequest.Message(role: "user", content: "oi")]
        )
        let data = try! JSONEncoder().encode(request)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("gpt-4o"))
        XCTAssertTrue(json.contains("oi"))
    }

    func testResponseDecoding() {
        let json = #"{"id":"chat-123","choices":[{"message":{"role":"assistant","content":"OK"},"finish_reason":"stop"}]}"#
        let data = json.data(using: .utf8)!
        let response = try! JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        XCTAssertEqual(response.id, "chat-123")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ChatCompletionModelsTests`
Expected: FAIL - "Cannot find type ChatCompletionRequest"

**Step 3: Write minimal implementation**

```swift
// Sources/CodexUsageCore/Networking/ChatCompletionModels.swift
import Foundation

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

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }

    public struct Message: Codable {
        public let role: String?
        public let content: String?
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ChatCompletionModelsTests`
Expected: PASS

---

## Task 2: ChatCompletionClient

**Files:**
- Create: `Sources/CodexUsageCore/Networking/ChatCompletionClient.swift`
- Test: `Tests/CodexUsageCoreTests/ChatCompletionClientTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/CodexUsageCoreTests/ChatCompletionClientTests.swift
import XCTest
@testable import CodexUsageCore

final class ChatCompletionClientTests: XCTestCase {
    func testSendPingSucceeds() async throws {
        let mockHTTP = MockHTTPClient(responseData: Data(), statusCode: 200)
        let client = ChatCompletionClient(httpClient: mockHTTP)
        try await client.sendPing(accessToken: "test-token")
    }

    func testSendPingUnauthorized() async throws {
        let mockHTTP = MockHTTPClient(responseData: Data(), statusCode: 401)
        let client = ChatCompletionClient(httpClient: mockHTTP)
        do {
            try await client.sendPing(accessToken: "bad-token")
            XCTFail("Expected error")
        } catch ChatCompletionError.unauthorized {
            // expected
        }
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ChatCompletionClientTests`
Expected: FAIL - "Cannot find type ChatCompletionClient"

**Step 3: Write minimal implementation**

```swift
// Sources/CodexUsageCore/Networking/ChatCompletionClient.swift
import Foundation

public enum ChatCompletionError: Error {
    case unauthorized
    case serverError
    case invalidResponse
}

public struct ChatCompletionClient {
    private let tokenProvider: AccessTokenProviding
    private let httpClient: HTTPClient
    private let baseURL = URL(string: "https://api.openai.com")!

    public init(
        tokenProvider: AccessTokenProviding = AccessTokenProvider(),
        httpClient: HTTPClient = URLSessionHTTPClient()
    ) {
        self.tokenProvider = tokenProvider
        self.httpClient = httpClient
    }

    public func sendPing(accessToken: String) async throws {
        let request = ChatCompletionRequest(
            messages: [ChatCompletionRequest.Message(role: "user", content: "oi")]
        )
        let body = try JSONEncoder().encode(request)

        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("v1/chat/completions"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body

        let (_, response) = try await httpClient.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatCompletionError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return
        case 401, 403:
            throw ChatCompletionError.unauthorized
        default:
            throw ChatCompletionError.serverError
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ChatCompletionClientTests`
Expected: PASS

---

## Task 3: SessionKeepAlive

**Files:**
- Create: `Sources/CodexUsageCore/Refresh/SessionKeepAlive.swift`
- Test: `Tests/CodexUsageCoreTests/SessionKeepAliveTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/CodexUsageCoreTests/SessionKeepAliveTests.swift
import XCTest
@testable import CodexUsageCore

final class SessionKeepAliveTests: XCTestCase {
    func testStartsAndStops() async throws {
        let mockClient = MockChatCompletionClient()
        let keepAlive = SessionKeepAlive(client: mockClient)
        keepAlive.start()
        try await Task.sleep(nanoseconds: 100_000_000)
        keepAlive.stop()
        XCTAssertTrue(mockClient.pingCount > 0)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter SessionKeepAliveTests`
Expected: FAIL - "Cannot find type SessionKeepAlive"

**Step 3: Write minimal implementation**

```swift
// Sources/CodexUsageCore/Refresh/SessionKeepAlive.swift
import Foundation

public actor SessionKeepAlive {
    private let client: ChatCompletionClient
    private let intervalSeconds: TimeInterval = 5 * 60 * 60
    private var task: Task<Void, Never>?

    public init(client: ChatCompletionClient) {
        self.client = client
    }

    public func start() {
        stop()
        task = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.ping()
                try? await Task.sleep(nanoseconds: UInt64(self.intervalSeconds * 1_000_000_000))
            }
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
    }

    private func ping() async {
        do {
            try await client.sendPing(accessToken: "")
        } catch {
            print("SessionKeepAlive ping failed: \(error)")
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter SessionKeepAliveTests`
Expected: PASS

---

## Task 4: Integrate into AppModel

**Files:**
- Modify: `Sources/CodexUsageBar/App/AppModel.swift`

**Step 1: Add property and methods**

Add to AppModel class:

```swift
private var sessionKeepAlive: SessionKeepAlive?
```

Add new method:

```swift
private func startSessionKeepAlive() {
    guard !isSignedOut else { return }
    let tokenProvider = AccessTokenProvider(tokenStore: tokenStore, refresher: oauthSession)
    let client = ChatCompletionClient(tokenProvider: tokenProvider)
    sessionKeepAlive = SessionKeepAlive(client: client)
    sessionKeepAlive?.start()
}
```

Modify `rebuildServiceAndRefresh()` to start keep-alive at the end:

```swift
// After coordinator.startAutoRefresh(interval: refreshIntervalSeconds)
startSessionKeepAlive()
```

**Step 2: Verify build**

Run: `swift build`
Expected: SUCCESS

---

## Task 5: Build and test

**Step 1: Full build**

Run: `swift build`

**Step 2: Run all tests**

Run: `swift test`

---

## Files Summary

| File | Action |
|------|--------|
| `Sources/CodexUsageCore/Networking/ChatCompletionModels.swift` | Create |
| `Sources/CodexUsageCore/Networking/ChatCompletionClient.swift` | Create |
| `Sources/CodexUsageCore/Refresh/SessionKeepAlive.swift` | Create |
| `Sources/CodexUsageBar/App/AppModel.swift` | Modify |
| `Tests/CodexUsageCoreTests/ChatCompletionModelsTests.swift` | Create |
| `Tests/CodexUsageCoreTests/ChatCompletionClientTests.swift` | Create |
| `Tests/CodexUsageCoreTests/SessionKeepAliveTests.swift` | Create |

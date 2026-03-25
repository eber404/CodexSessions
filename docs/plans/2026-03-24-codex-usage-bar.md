# Codex Usage Bar Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a simple macOS menu bar app that shows Codex usage from OpenAI's usage endpoint with automatic local auth discovery and native OAuth fallback.

**Architecture:** Use a Swift Package with a testable core library for auth, parsing, network, refresh, and view models, plus a thin executable target that runs an AppKit/SwiftUI menu bar app. Persist app-managed OAuth credentials in Keychain and prefer local auth when available.

**Tech Stack:** Swift 6, AppKit, SwiftUI, Foundation, Security, ServiceManagement, XCTest

---

### Task 1: Package scaffold and target layout

**Files:**
- Create: `Package.swift`
- Create: `Sources/CodexUsageCore/`
- Create: `Sources/CodexUsageBar/main.swift`
- Create: `Tests/CodexUsageCoreTests/`

**Step 1: Write the failing test**

```swift
import XCTest
@testable import CodexUsageCore

final class PackageSmokeTests: XCTestCase {
    func testCoreModuleLoads() {
        XCTAssertEqual(AppConstants.appName, "Codex Usage Bar")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test`
Expected: FAIL because `CodexUsageCore` and `AppConstants` do not exist yet.

**Step 3: Write minimal implementation**

```swift
public enum AppConstants {
    public static let appName = "Codex Usage Bar"
}
```

Add package targets:

```swift
.library(name: "CodexUsageCore", targets: ["CodexUsageCore"]),
.executable(name: "CodexUsageBar", targets: ["CodexUsageBar"]),
.testTarget(name: "CodexUsageCoreTests", dependencies: ["CodexUsageCore"])
```

**Step 4: Run test to verify it passes**

Run: `swift test`
Expected: PASS

**Step 5: Commit**

If this folder becomes a git repo:

```bash
git add Package.swift Sources Tests
git commit -m "chore: scaffold codex usage bar package"
```

### Task 2: Auth discovery and normalized usage parsing

**Files:**
- Create: `Sources/CodexUsageCore/Auth/AuthSource.swift`
- Create: `Sources/CodexUsageCore/Auth/AuthDiscovery.swift`
- Create: `Sources/CodexUsageCore/Models/UsageSnapshot.swift`
- Create: `Sources/CodexUsageCore/Parsing/UsageResponseParser.swift`
- Test: `Tests/CodexUsageCoreTests/AuthDiscoveryTests.swift`
- Test: `Tests/CodexUsageCoreTests/UsageResponseParserTests.swift`

**Step 1: Write the failing test**

```swift
func testParserMapsShortAndWeeklyWindows() throws {
    let snapshot = try UsageResponseParser().parse(data: fixtureData)
    XCTAssertEqual(snapshot.windows.count, 2)
    XCTAssertEqual(snapshot.windows.first?.kind, .shortWindow)
    XCTAssertEqual(snapshot.windows.last?.kind, .weekly)
}
```

```swift
func testDiscoveryPrefersCustomPathOverFallbacks() throws {
    let source = try AuthDiscovery(fileManager: fakeFileManager).resolve(preferredPath: "/tmp/auth.json")
    XCTAssertEqual(source, .localAuthFile(path: "/tmp/auth.json"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AuthDiscoveryTests && swift test --filter UsageResponseParserTests`
Expected: FAIL because types do not exist yet.

**Step 3: Write minimal implementation**

Create a normalized model:

```swift
public struct UsageSnapshot: Equatable, Sendable {
    public var accountEmail: String?
    public var sourceLabel: String
    public var windows: [UsageWindow]
    public var fetchedAt: Date
}
```

Create source selection:

```swift
public enum AuthSource: Equatable, Sendable {
    case localAuthFile(path: String)
    case oauthKeychain(service: String, account: String)
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AuthDiscoveryTests && swift test --filter UsageResponseParserTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CodexUsageCore Tests/CodexUsageCoreTests
git commit -m "feat: add auth discovery and usage parsing"
```

### Task 3: Usage client and refresh coordinator

**Files:**
- Create: `Sources/CodexUsageCore/Networking/UsageRequestBuilder.swift`
- Create: `Sources/CodexUsageCore/Networking/UsageClient.swift`
- Create: `Sources/CodexUsageCore/Refresh/RefreshCoordinator.swift`
- Test: `Tests/CodexUsageCoreTests/UsageRequestBuilderTests.swift`
- Test: `Tests/CodexUsageCoreTests/RefreshCoordinatorTests.swift`

**Step 1: Write the failing test**

```swift
func testBuildsUsageEndpointRequest() throws {
    let request = try UsageRequestBuilder().makeRequest(accessToken: "token")
    XCTAssertEqual(request.url?.absoluteString, "https://chatgpt.com/backend-api/wham/usage")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
}
```

```swift
func testFailedRefreshKeepsLastSnapshotAndMarksStateStale() async throws {
    let coordinator = RefreshCoordinator(client: failingClient, clock: clock)
    await coordinator.load()
    XCTAssertTrue(coordinator.state.isStale)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter UsageRequestBuilderTests && swift test --filter RefreshCoordinatorTests`
Expected: FAIL because request builder and coordinator do not exist.

**Step 3: Write minimal implementation**

```swift
var request = URLRequest(url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!)
request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Accept")
```

Use async refresh state with last-success snapshot preservation.

**Step 4: Run test to verify it passes**

Run: `swift test --filter UsageRequestBuilderTests && swift test --filter RefreshCoordinatorTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CodexUsageCore Tests/CodexUsageCoreTests
git commit -m "feat: add usage client and refresh coordinator"
```

### Task 4: Menu bar app and settings UI

**Files:**
- Create: `Sources/CodexUsageBar/App/AppDelegate.swift`
- Create: `Sources/CodexUsageBar/App/MenuBarController.swift`
- Create: `Sources/CodexUsageBar/UI/MenuContentView.swift`
- Create: `Sources/CodexUsageBar/UI/SettingsView.swift`
- Create: `Sources/CodexUsageBar/UI/IconRenderer.swift`

**Step 1: Write the failing test**

```swift
func testIconRendererProducesTopAndBottomBars() {
    let image = IconRenderer().makeImage(shortProgress: 0.5, weeklyProgress: 0.25, isStale: false)
    XCTAssertNotNil(image)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter IconRendererTests`
Expected: FAIL because `IconRenderer` does not exist.

**Step 3: Write minimal implementation**

Create an `NSStatusItem`-based controller that:

- renders a two-bar icon
- opens a popover with usage rows and actions
- shows settings from a separate window
- runs with `NSApp.setActivationPolicy(.accessory)`

**Step 4: Run test to verify it passes**

Run: `swift test --filter IconRendererTests && swift build`
Expected: PASS and build succeeds.

**Step 5: Commit**

```bash
git add Sources/CodexUsageBar Tests/CodexUsageCoreTests
git commit -m "feat: add menu bar interface"
```

### Task 5: OAuth fallback, launch-at-login, and docs

**Files:**
- Create: `Sources/CodexUsageCore/Auth/OAuthSession.swift`
- Create: `Sources/CodexUsageCore/Auth/KeychainTokenStore.swift`
- Create: `Sources/CodexUsageBar/App/LoginItemManager.swift`
- Modify: `Sources/CodexUsageBar/UI/SettingsView.swift`
- Create: `README.md`
- Test: `Tests/CodexUsageCoreTests/KeychainTokenStoreTests.swift`

**Step 1: Write the failing test**

```swift
func testPrefersKeychainOauthWhenNoLocalAuthExists() throws {
    let resolver = AuthResolver(discovery: emptyDiscovery, tokenStore: tokenStore)
    XCTAssertEqual(try resolver.resolve(), .oauthKeychain(service: "CodexUsageBar", account: "default"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter KeychainTokenStoreTests`
Expected: FAIL because OAuth storage and resolver logic are incomplete.

**Step 3: Write minimal implementation**

Implement:

- PKCE-based OAuth session wrapper
- secure token persistence in Keychain
- settings actions for connect/disconnect
- launch-at-login toggle
- README with build and run instructions

**Step 4: Run test to verify it passes**

Run: `swift test && swift build`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources Tests README.md
git commit -m "feat: add oauth fallback and app settings"
```

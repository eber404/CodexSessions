# Session Keep-Alive Configurável - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Implement configurable keep-alive with toggle, first-hour slider, and visual timeline.

**Architecture:** SessionScheduler calculates intervals; SessionTimelineView renders 24h timeline; AppModel manages settings and enables/disables keep-alive; SessionKeepAlive respects isEnabled flag.

**Tech Stack:** Swift, SwiftUI (for timeline), existing CodexWatchCore components

---

## Task 1: SessionScheduler

Calculates session intervals and timeline blocks.

**Files:**
- Create: `Sources/CodexWatchCore/Refresh/SessionScheduler.swift`
- Test: `Tests/CodexWatchCoreTests/SessionSchedulerTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/CodexWatchCoreTests/SessionSchedulerTests.swift
import XCTest
@testable import CodexWatchCore

final class SessionSchedulerTests: XCTestCase {
    func testCalculateIntervalsFirstHour9() {
        let scheduler = SessionScheduler()
        let intervals = scheduler.calculateIntervals(firstHour: 9, count: 6)
        let hours = intervals.map { Calendar.current.component(.hour, from: $0) }
        XCTAssertEqual(hours, [9, 14, 19, 0, 5, 10])
    }

    func testCalculateNextPingFromNow() {
        let scheduler = SessionScheduler()
        let nextPing = scheduler.calculateNextPing(firstHour: 9)
        let now = Date()
        XCTAssertTrue(nextPing > now, "Next ping should be in the future")
    }

    func testCalculateTimelineBlocks() {
        let scheduler = SessionScheduler()
        let blocks = scheduler.calculateTimelineBlocks(firstHour: 9)
        XCTAssertEqual(blocks.count, 5) // 5 blocks of 5h = 25h covers next day
        XCTAssertTrue(blocks.first?.isNext == true) // First block is next
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter SessionSchedulerTests`
Expected: FAIL - "Cannot find type SessionScheduler"

**Step 3: Write minimal implementation**

```swift
// Sources/CodexWatchCore/Refresh/SessionScheduler.swift
import Foundation

public struct TimeBlock: Identifiable {
    public let id = UUID()
    public let startHour: Int
    public let endHour: Int
    public let label: String
    public let isNext: Bool

    public init(startHour: Int, endHour: Int, label: String, isNext: Bool) {
        self.startHour = startHour
        self.endHour = endHour
        self.label = label
        self.isNext = isNext
    }
}

public final class SessionScheduler {
    private let calendar = Calendar.current

    public init() {}

    public func calculateIntervals(firstHour: Int, count: Int) -> [Date] {
        var intervals: [Date] = []
        var currentHour = firstHour

        for _ in 0..<count {
            if let date = nextIntervalDate(hour: currentHour) {
                intervals.append(date)
            }
            currentHour = (currentHour + 5) % 24
        }

        return intervals
    }

    public func calculateNextPing(firstHour: Int) -> Date {
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        var hoursUntilNext = firstHour - currentHour
        if hoursUntilNext <= 0 {
            hoursUntilNext += 24
        }

        return calendar.date(byAdding: .hour, value: hoursUntilNext, to: now) ?? now
    }

    public func calculateTimelineBlocks(firstHour: Int) -> [TimeBlock] {
        var blocks: [TimeBlock] = []
        var currentHour = firstHour
        let now = Date()
        let currentHourNow = calendar.component(.hour, from: now)

        for i in 0..<5 {
            let endHour = (currentHour + 5) % 24
            let isNext = currentHour == firstHour

            let label = String(format: "%02d:00", currentHour)
            let block = TimeBlock(
                startHour: currentHour,
                endHour: endHour,
                label: label,
                isNext: isNext
            )
            blocks.append(block)

            currentHour = (currentHour + 5) % 24
        }

        return blocks
    }

    private func nextIntervalDate(hour: Int) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        components.second = 0

        guard let date = calendar.date(from: components) else { return nil }

        if date <= Date() {
            return calendar.date(byAdding: .day, value: 1, to: date)
        }
        return date
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter SessionSchedulerTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CodexWatchCore/Refresh/SessionScheduler.swift Tests/CodexWatchCoreTests/SessionSchedulerTests.swift
git commit -m "feat: add SessionScheduler for interval calculations"
```

---

## Task 2: SessionTimelineView

SwiftUI view showing 24h timeline with 5h blocks.

**Files:**
- Create: `Sources/CodexWatch/UI/SessionTimelineView.swift`
- Test: `Tests/CodexWatchCoreTests/SessionTimelineViewTests.swift`

**Step 1: Write the failing test**

```swift
// Tests/CodexWatchCoreTests/SessionTimelineViewTests.swift
import XCTest
@testable import CodexWatch

final class SessionTimelineViewTests: XCTestCase {
    func testTimelineRendersBlocks() {
        let scheduler = SessionScheduler()
        let blocks = scheduler.calculateTimelineBlocks(firstHour: 9)
        let view = SessionTimelineView(blocks: blocks, firstHour: 9)
        // Just verify it doesn't crash
        XCTAssertNotNil(view)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter SessionTimelineViewTests`
Expected: FAIL - "Cannot find type SessionTimelineView"

**Step 3: Write minimal implementation**

```swift
// Sources/CodexWatch/UI/SessionTimelineView.swift
import SwiftUI

public struct SessionTimelineView: View {
    let blocks: [TimeBlock]
    let firstHour: Int

    public init(blocks: [TimeBlock], firstHour: Int) {
        self.blocks = blocks
        self.firstHour = firstHour
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timeline de hoje")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                ForEach(blocks) { block in
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(block.isNext ? Color.green : Color.blue.opacity(0.6))
                            .frame(height: 24)
                            .cornerRadius(4)

                        Text(block.label)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack {
                Text("00")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Spacer()
                Text("24")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter SessionTimelineViewTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CodexWatch/UI/SessionTimelineView.swift Tests/CodexWatchCoreTests/SessionTimelineViewTests.swift
git commit -m "feat: add SessionTimelineView for visual timeline"
```

---

## Task 3: AppModel Updates

Add keepAliveEnabled, firstHour properties and settings persistence.

**Files:**
- Modify: `Sources/CodexWatch/App/AppModel.swift`

**Step 1: Add new properties**

Add to `AppModel`:

```swift
private enum PreferenceKey {
    // ... existing keys
    static let keepAliveEnabled = "settings.keepAliveEnabled"
    static let firstHour = "settings.firstHour"
}

@Published var keepAliveEnabled: Bool = false
@Published var firstHour: Int = 9
private var keepAliveTask: Task<Void, Never>?
```

**Step 2: Update restoreUserSettings()**

```swift
func restoreUserSettings() {
    // ... existing code

    keepAliveEnabled = userDefaults.bool(forKey: PreferenceKey.keepAliveEnabled)
    if userDefaults.object(forKey: PreferenceKey.firstHour) != nil {
        firstHour = userDefaults.integer(forKey: PreferenceKey.firstHour)
    }
}
```

**Step 3: Add methods**

```swift
func setKeepAliveEnabled(_ enabled: Bool) {
    keepAliveEnabled = enabled
    userDefaults.set(enabled, forKey: PreferenceKey.keepAliveEnabled)

    if enabled {
        startSessionKeepAlive()
    } else {
        stopSessionKeepAlive()
    }
}

func setFirstHour(_ hour: Int) {
    firstHour = hour
    userDefaults.set(hour, forKey: PreferenceKey.firstHour)

    if keepAliveEnabled {
        startSessionKeepAlive()
    }
}

private func stopSessionKeepAlive() {
    keepAliveTask?.cancel()
    keepAliveTask = nil
    sessionKeepAlive = nil
}
```

**Step 4: Update startSessionKeepAlive() to use isEnabled**

Modify to check `keepAliveEnabled` first:

```swift
private func startSessionKeepAlive() {
    guard !isSignedOut, keepAliveEnabled else { return }
    // ... rest of implementation
}
```

**Step 5: Build and test**

Run: `swift build`
Run: `swift test`

**Step 6: Commit**

```bash
git add Sources/CodexWatch/App/AppModel.swift
git commit -m "feat: add keepAliveEnabled and firstHour settings to AppModel"
```

---

## Task 4: SettingsView Updates

Integrate toggle, slider, and timeline into Settings.

**Files:**
- Modify: `Sources/CodexWatch/UI/SettingsView.swift`

**Step 1: Read current SettingsView**

Run: `cat Sources/CodexWatch/UI/SettingsView.swift`

**Step 2: Add Keep-Alive section**

Add after existing settings sections:

```swift
// In SettingsView body, after other sections:

Section {
    Toggle("Ativar Session Keep-Alive", isOn: $appModel.keepAliveEnabled)
        .onChange(of: appModel.keepAliveEnabled) { _, newValue in
            appModel.setKeepAliveEnabled(newValue)
        }

    if appModel.keepAliveEnabled {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Primeira hora do dia:")
                Text(String(format: "%02d:00", appModel.firstHour))
                    .fontWeight(.semibold)
            }

            Slider(
                value: Binding(
                    get: { Double(appModel.firstHour) },
                    set: { appModel.setFirstHour(Int($0)) }
                ),
                in: 0...23,
                step: 1
            )

            let scheduler = SessionScheduler()
            let blocks = scheduler.calculateTimelineBlocks(firstHour: appModel.firstHour)
            SessionTimelineView(blocks: blocks, firstHour: appModel.firstHour)

            let nextPing = scheduler.calculateNextPing(firstHour: appModel.firstHour)
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            Text("Próximo envio: \(formatter.string(from: nextPing))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} header: {
    Text("Session Keep-Alive")
}
```

**Step 3: Build and test**

Run: `swift build`
Run: `swift test`

**Step 4: Commit**

```bash
git add Sources/CodexWatch/UI/SettingsView.swift
git commit -m "feat: add keep-alive settings UI with toggle, slider, and timeline"
```

---

## Task 5: Update SessionKeepAlive

Add isEnabled flag and firstHour parameter.

**Files:**
- Modify: `Sources/CodexWatchCore/Refresh/SessionKeepAlive.swift`

**Step 1: Update SessionKeepAlive**

```swift
public actor SessionKeepAlive {
    private let client: ChatCompletionClient
    private let intervalSeconds: TimeInterval = 5 * 60 * 60
    private var task: Task<Void, Never>?
    private var isEnabled: Bool = false
    private var firstHour: Int = 9

    public init(client: ChatCompletionClient) {
        self.client = client
    }

    public func configure(isEnabled: Bool, firstHour: Int) {
        self.isEnabled = isEnabled
        self.firstHour = firstHour
    }

    public func start(accessToken: String) {
        stop()
        guard isEnabled else { return }

        task = Task { [weak self] in
            guard let self else { return }

            // Wait until first hour
            if let waitTime = self.timeUntilFirstHour() {
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }

            guard !Task.isCancelled else { return }

            while !Task.isCancelled {
                await self.ping(accessToken: accessToken)
                try? await Task.sleep(nanoseconds: UInt64(self.intervalSeconds * 1_000_000_000))
            }
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
    }

    private func timeUntilFirstHour() -> TimeInterval? {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        var hoursUntil = firstHour - currentHour
        if hoursUntil <= 0 {
            hoursUntil += 24
        }

        return TimeInterval(hoursUntil * 3600)
    }

    private func ping(accessToken: String) async {
        do {
            try await client.sendPing(accessToken: accessToken)
        } catch {
            print("SessionKeepAlive ping failed: \(error)")
        }
    }
}
```

**Step 2: Build and test**

Run: `swift build`
Run: `swift test --filter SessionKeepAlive`

**Step 3: Commit**

```bash
git add Sources/CodexWatchCore/Refresh/SessionKeepAlive.swift
git commit -m "feat: update SessionKeepAlive with isEnabled and firstHour support"
```

---

## Task 6: Final Build and Test

**Step 1: Full build**

Run: `swift build`

**Step 2: All tests**

Run: `swift test`

---

## Files Summary

| File | Action |
|------|--------|
| `Sources/CodexWatchCore/Refresh/SessionScheduler.swift` | Create |
| `Sources/CodexWatch/UI/SessionTimelineView.swift` | Create |
| `Sources/CodexWatch/App/AppModel.swift` | Modify |
| `Sources/CodexWatch/UI/SettingsView.swift` | Modify |
| `Sources/CodexWatchCore/Refresh/SessionKeepAlive.swift` | Modify |
| `Tests/CodexWatchCoreTests/SessionSchedulerTests.swift` | Create |
| `Tests/CodexWatchCoreTests/SessionTimelineViewTests.swift` | Create |

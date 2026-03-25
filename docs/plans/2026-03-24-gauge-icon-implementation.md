# Gauge Icon Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current two-bar menu icon with a clearer dual-ring circular gauge that communicates weekly and short-window usage.

**Architecture:** Keep the existing `IconRendererModel` inputs and `MenuBarController` call site unchanged. Update only `IconRenderer` drawing internals to render two concentric arcs in template style, and adjust `IconRendererTests` to assert ring geometry metadata instead of bar-specific names.

**Tech Stack:** Swift 6, AppKit, XCTest

---

### Task 1: Introduce ring layout metadata with tests

**Files:**
- Modify: `Tests/CodexUsageCoreTests/IconRendererTests.swift`
- Modify: `Sources/CodexUsageCore/UI/IconRenderer.swift`

**Step 1: Write the failing test**

```swift
func testIconRendererProducesOuterAndInnerRings() {
    let model = IconRendererModel(shortProgress: 0.5, weeklyProgress: 0.25, isStale: false)
    let rings = IconRenderer().ringLayout(for: model)

    XCTAssertEqual(rings.count, 2)
    XCTAssertEqual(rings[0].name, "weekly")
    XCTAssertEqual(rings[1].name, "short")
    XCTAssertGreaterThan(rings[0].radius, rings[1].radius)
}
```

```swift
func testIconRendererKeepsMinimalVisibleArcAtZeroProgress() {
    let model = IconRendererModel(shortProgress: 0, weeklyProgress: 0, isStale: false)
    let rings = IconRenderer().ringLayout(for: model)

    XCTAssertGreaterThan(rings[0].endAngle - rings[0].startAngle, 0)
    XCTAssertGreaterThan(rings[1].endAngle - rings[1].startAngle, 0)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter IconRendererTests`
Expected: FAIL because `ringLayout` and ring geometry types do not exist.

**Step 3: Write minimal implementation**

```swift
public struct IconRing: Equatable, Sendable {
    public var name: String
    public var radius: Double
    public var lineWidth: Double
    public var startAngle: Double
    public var endAngle: Double
}

public func ringLayout(for model: IconRendererModel) -> [IconRing] {
    // map weekly + short progress to two ring arcs
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter IconRendererTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Tests/CodexUsageCoreTests/IconRendererTests.swift Sources/CodexUsageCore/UI/IconRenderer.swift
git commit -m "feat: render menu icon as dual-ring gauge"
```

### Task 2: Draw dual-ring gauge image and verify build

**Files:**
- Modify: `Sources/CodexUsageCore/UI/IconRenderer.swift`

**Step 1: Write the failing test**

```swift
func testRingLayoutUsesExpectedArcStartReference() {
    let model = IconRendererModel(shortProgress: 0.5, weeklyProgress: 0.5, isStale: false)
    let rings = IconRenderer().ringLayout(for: model)
    XCTAssertEqual(rings[0].startAngle, -90, accuracy: 0.001)
    XCTAssertEqual(rings[1].startAngle, -90, accuracy: 0.001)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter IconRendererTests`
Expected: FAIL until the gauge arc mapping is implemented exactly.

**Step 3: Write minimal implementation**

```swift
let path = NSBezierPath()
path.appendArc(withCenter: center,
               radius: ring.radius,
               startAngle: CGFloat(ring.startAngle),
               endAngle: CGFloat(ring.endAngle),
               clockwise: false)
path.lineWidth = CGFloat(ring.lineWidth)
path.stroke()
```

Render weekly as the outer ring and short as the inner ring in template color; keep stale color behavior unchanged.

**Step 4: Run test to verify it passes**

Run: `swift test --filter IconRendererTests && swift build`
Expected: PASS and build succeeds.

**Step 5: Commit**

```bash
git add Sources/CodexUsageCore/UI/IconRenderer.swift Tests/CodexUsageCoreTests/IconRendererTests.swift
git commit -m "refactor: replace bar geometry with ring geometry"
```

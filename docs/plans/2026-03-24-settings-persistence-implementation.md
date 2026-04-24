# Settings Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Persist refresh interval and launch-at-login settings and restore them on app startup.

**Architecture:** Add a tiny `UserDefaults`-backed preferences layer inside `AppModel` so persistence stays centralized. `SettingsView` updates model properties and model writes preferences immediately while applying runtime effects (refresh scheduler + login item manager).

**Tech Stack:** Swift, SwiftUI, Foundation `UserDefaults`, existing `LoginItemManager`.

---

### Task 1: Add persisted settings plumbing in AppModel

**Files:**
- Modify: `Sources/CodexWatch/App/AppModel.swift`

**Step 1: Write failing test**

Create a test target + tests for startup restore (Task 3 covers concrete file/tests).

**Step 2: Run test to verify it fails**

Run: `swift test`
Expected: test fails because settings are not restored.

**Step 3: Write minimal implementation**

Implement defaults keys, load-on-start, and update methods in `AppModel`.

**Step 4: Run test to verify it passes**

Run: `swift test`
Expected: restore test passes.

**Step 5: Commit**

Commit with focused message after verification.

### Task 2: Bind SettingsView to persisted model values

**Files:**
- Modify: `Sources/CodexWatch/UI/SettingsView.swift`

**Step 1: Write failing test**

Covered by model-level tests and manual verification for view binding.

**Step 2: Run test to verify it fails**

Run: `swift test`

**Step 3: Write minimal implementation**

Use model-backed values for refresh interval + launch-at-login and route changes to model methods.

**Step 4: Run test to verify it passes**

Run: `swift test`

**Step 5: Commit**

Commit with focused message after verification.

### Task 3: Add executable-target tests for persistence

**Files:**
- Modify: `Package.swift`
- Create: `Tests/CodexWatchTests/AppModelSettingsPersistenceTests.swift`

**Step 1: Write the failing test**

Add tests for:
- restoring refresh interval from defaults on `start()`
- persisting refresh interval on update
- restoring/persisting launch-at-login toggle state

**Step 2: Run test to verify it fails**

Run: `swift test`
Expected: fails until model persistence exists.

**Step 3: Write minimal implementation**

Add dependency injection hooks for `UserDefaults` and login item state in model.

**Step 4: Run test to verify it passes**

Run: `swift test`
Expected: all tests pass.

**Step 5: Commit**

Commit with focused message after verification.

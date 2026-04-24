# Usage Bar Threshold Colors Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Color usage progress bars by threshold: green below 80%, orange from 80% to 89%, red from 90% upward.

**Architecture:** Keep existing `ProgressView` in `MenuContentView` and add a small threshold helper for tint selection. Test boundary mapping directly so UI behavior stays stable with minimal code.

**Tech Stack:** Swift, SwiftUI, XCTest

---

### Task 1: Add failing threshold mapping test

**Files:**
- Create or modify: `Tests/CodexSessionsTests/*UsageBar*Tests.swift` or nearest view test file
- Modify: `Sources/CodexUsageBar/UI/MenuContentView.swift`

**Step 1: Write the failing test**

Add test for exact boundaries:
- `0.79` -> green
- `0.80` -> orange
- `0.89` -> orange
- `0.90` -> red

**Step 2: Run test to verify it fails**

Run: `swift test --filter UsageBar`
Expected: FAIL because helper does not exist yet.

**Step 3: Write minimal implementation**

Add small helper to map ratio to threshold bucket/color.

**Step 4: Run test to verify it passes**

Run: `swift test --filter UsageBar`
Expected: PASS.

### Task 2: Apply tint to progress bar

**Files:**
- Modify: `Sources/CodexUsageBar/UI/MenuContentView.swift`

**Step 1: Write minimal UI change**

Apply `.tint(...)` to `ProgressView(value: ratio)` using threshold helper.

**Step 2: Verify build compiles**

Run: `swift build`
Expected: PASS.

### Task 3: Verify focused tests

**Files:**
- Relevant threshold/view tests

**Step 1: Run focused tests**

Run: `swift test --filter UsageBar`

**Step 2: Fix only minimal issues**

No extra UI refactors.

### Task 4: Full verification

**Files:**
- Whole package

**Step 1: Run full test suite**

Run: `swift test`
Expected: all tests pass.

**Step 2: Run build**

Run: `swift build`
Expected: build succeeds.

### Task 5: Commit

**Step 1: Commit once verified**

```bash
git add Sources/CodexUsageBar/UI/MenuContentView.swift Tests/CodexSessionsTests/*UsageBar*Tests.swift docs/plans/2026-04-24-usage-bar-threshold-colors-design.md docs/plans/2026-04-24-usage-bar-threshold-colors-plan.md
git commit -m "ui: add threshold colors to usage bars"
```

Plan complete and saved to `docs/plans/2026-04-24-usage-bar-threshold-colors-plan.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

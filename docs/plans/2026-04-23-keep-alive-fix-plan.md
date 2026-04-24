# Keep-Alive Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Session Keep-Alive hit Codex-aligned session endpoint, stop duplicate background loops, and surface exact ping failures.

**Architecture:** Keep scheduling in `SessionKeepAlive`, but inject fresh-token resolution per ping instead of capturing one token forever. Replace generic chat completions ping client with Codex session keep-alive client, and stop prior keep-alive actor before replacing it in `AppModel`.

**Tech Stack:** Swift, Swift Concurrency, XCTest, URLSession

---

### Task 1: Add failing lifecycle regression test

**Files:**
- Modify: `Tests/CodexSessionsTests/AppModelSettingsPersistenceTests.swift` or create targeted app-model test file if cleaner
- Read: `Sources/CodexUsageBar/App/AppModel.swift`

**Step 1: Write failing test**

Create test that starts keep-alive twice and proves old instance gets stopped before replacement.

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppModel`
Expected: FAIL because old keep-alive task keeps running.

**Step 3: Write minimal implementation**

Update `AppModel.startSessionKeepAlive()` to stop existing actor before replacement.

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppModel`
Expected: PASS.

### Task 2: Add failing keep-alive endpoint test

**Files:**
- Modify: `Tests/CodexUsageCoreTests/ChatCompletionClientTests.swift` or replace with new keep-alive client tests
- Modify/Create: `Sources/CodexUsageCore/Networking/*KeepAlive*Client*.swift`

**Step 1: Write failing test**

Assert request URL targets Codex session endpoint on `chatgpt.com`, not `api.openai.com/v1/chat/completions`.

**Step 2: Run test to verify it fails**

Run: `swift test --filter KeepAlive`
Expected: FAIL because current client targets chat completions.

**Step 3: Write minimal implementation**

Create dedicated keep-alive client for Codex session endpoint. Keep request builder simple, explicit, no extra abstractions unless needed.

**Step 4: Run test to verify it passes**

Run: `swift test --filter KeepAlive`
Expected: PASS.

### Task 3: Add failing status-detail test

**Files:**
- Modify: `Tests/CodexUsageCoreTests/*KeepAlive*Tests.swift`
- Modify: `Sources/CodexUsageCore/Networking/*KeepAlive*Client*.swift`

**Step 1: Write failing test**

Assert non-200 response returns error containing exact HTTP status and short body snippet.

**Step 2: Run test to verify it fails**

Run: `swift test --filter KeepAlive`
Expected: FAIL because current code collapses failures into generic `serverError`.

**Step 3: Write minimal implementation**

Add richer error enum, parse response body snippet, map status precisely.

**Step 4: Run test to verify it passes**

Run: `swift test --filter KeepAlive`
Expected: PASS.

### Task 4: Refresh token per ping

**Files:**
- Modify: `Sources/CodexUsageCore/Refresh/SessionKeepAlive.swift`
- Modify: `Sources/CodexUsageBar/App/AppModel.swift`
- Test: `Tests/CodexUsageCoreTests/SessionKeepAliveTests.swift`

**Step 1: Write failing test**

Assert ping loop requests token through injected provider when ping executes, not only at startup.

**Step 2: Run test to verify it fails**

Run: `swift test --filter SessionKeepAlive`
Expected: FAIL because current implementation captures token in `start(accessToken:)`.

**Step 3: Write minimal implementation**

Change keep-alive actor API to accept token resolver closure or provider object plus source. Resolve token inside ping path.

**Step 4: Run test to verify it passes**

Run: `swift test --filter SessionKeepAlive`
Expected: PASS.

### Task 5: Verify targeted suite

**Files:**
- Test: `Tests/CodexUsageCoreTests/SessionKeepAliveTests.swift`
- Test: `Tests/CodexUsageCoreTests/*KeepAlive*Tests.swift`
- Test: `Tests/CodexSessionsTests/*AppModel*Tests.swift`

**Step 1: Run focused tests**

Run: `swift test --filter SessionKeepAlive`

**Step 2: Run broader keep-alive/app-model tests**

Run: `swift test --filter KeepAlive`

**Step 3: Fix any failures**

Only minimal fixes tied to failing assertions.

### Task 6: Full verification

**Files:**
- Whole package

**Step 1: Run full test suite**

Run: `swift test`
Expected: all tests pass.

**Step 2: Run build**

Run: `swift build`
Expected: build succeeds.

Plan complete and saved to `docs/plans/2026-04-23-keep-alive-fix-plan.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

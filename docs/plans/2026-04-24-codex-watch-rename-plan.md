# Codex Watch Rename Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename project fully from CodexWatch / CodexUsage naming to Codex Watch across code, folders, package metadata, tests, and docs.

**Architecture:** Perform a full in-place rename of package/targets/modules/folders first, then update source/test imports and user-facing strings, then sweep docs and repo references. Finish with repo-wide search and full Swift verification.

**Tech Stack:** Swift, SwiftUI, Swift Package Manager, Markdown docs

---

### Task 1: Rename package and target definitions

**Files:**
- Modify: `Package.swift`

**Step 1: Write failing verification target**

Use build as failure signal for package rename changes.

**Step 2: Run build to verify current baseline**

Run: `swift build`
Expected: PASS before rename.

**Step 3: Write minimal implementation**

Rename package string to `codex-watch`, targets/modules to `CodexWatchCore`, `CodexWatch`, `CodexWatchCoreTests`, `CodexWatchTests`.

**Step 4: Run build to verify expected temporary failures surface missing path/import updates**

Run: `swift build`
Expected: FAIL until folder/import updates are completed.

### Task 2: Rename source and test folder paths

**Files:**
- Move: `Sources/CodexWatchCore` -> `Sources/CodexWatchCore`
- Move: `Sources/CodexWatch` -> `Sources/CodexWatch`
- Move: `Tests/CodexWatchCoreTests` -> `Tests/CodexWatchCoreTests`
- Move: `Tests/CodexWatchTests` -> `Tests/CodexWatchTests`

**Step 1: Move directories**

Use git-aware moves so repo history remains understandable.

**Step 2: Run build**

Run: `swift build`
Expected: FAIL on old imports/strings still referencing old modules.

### Task 3: Rename imports and module references

**Files:**
- Modify all `.swift` files under `Sources/` and `Tests/`

**Step 1: Write failing focused test/build check**

Run build after folder move to expose unresolved imports.

**Step 2: Write minimal implementation**

Replace imports and `@testable import` references:
- `CodexWatchCore` -> `CodexWatchCore`
- `CodexWatch` -> `CodexWatch`

**Step 3: Run build**

Run: `swift build`
Expected: PASS or fail only on remaining string/path references.

### Task 4: Rename user-facing strings and comments

**Files:**
- Modify source files, `README.md`, `CHANGELOG.md`, `AGENTS.md`

**Step 1: Update product strings**

Examples:
- `CodexWatch` -> `Codex Watch`
- settings window titles
- README headings/descriptions

**Step 2: Update code comments/header comments where old names remain**

**Step 3: Run targeted search**

Run repo search for `CodexWatch|CodexUsage|codex-watch`.
Expected: only intentional references remain, ideally none.

### Task 5: Sweep docs and plan docs

**Files:**
- Modify all `docs/**/*.md`

**Step 1: Replace old project/module names in docs**

Keep wording coherent after replacements.

**Step 2: Re-run search**

Run repo search for old names.
Expected: no stale references left.

### Task 6: Full verification

**Files:**
- Whole package

**Step 1: Run full test suite**

Run: `swift test`
Expected: all tests pass.

**Step 2: Run build**

Run: `swift build`
Expected: build succeeds.

### Task 7: Review status without commit

**Files:**
- Whole repo

**Step 1: Inspect `git status -sb`**

Expected: rename diff present, no commit created.

Plan complete and saved to `docs/plans/2026-04-24-codex-watch-rename-plan.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

# Codex Watch Rename Design

## Goal

Rename project from CodexWatch / CodexUsage naming to Codex Watch across product text, technical identifiers, package metadata, folders, tests, docs, and repository references.

## Scope

This rename includes all of:

- Product-facing strings
- Swift package name
- Library / executable / test target names
- Module imports
- Source and test folder names
- Documentation and plan docs
- Local repository path/name references where stored in repo files

This does not include remote GitHub repository rename itself unless explicitly requested later through GitHub settings/API.

## Chosen Approach

Perform a full in-place rename with no backward-compatibility aliases.

## Alternatives Considered

### 1. Product-only rename

Rejected. Leaves technical debt and contradicts request to rename everything.

### 2. Partial internal rename while keeping folder paths

Rejected. Reduces churn, but still leaves old naming spread through project.

### 3. Full in-place rename

Accepted. Cleanest end state and best match for requested scope.

## Design

### Naming Targets

- Product name: `Codex Watch`
- Executable target/module: `CodexWatch`
- Core library target/module: `CodexWatchCore`
- App source folder path: `Sources/CodexWatch`
- Core source folder path: `Sources/CodexWatchCore`
- Test target/module names: `CodexWatchTests`, `CodexWatchCoreTests`
- Repository/package name string: `codex-watch`

### Code Changes

- Update `Package.swift` target declarations and dependencies.
- Rename imports in source and test files.
- Rename file comments and internal product strings like menu title and settings window title.
- Update docs and instructions to use new names consistently.

### Folder Changes

- Move source and test directories to new names so path structure matches module names.
- Keep file contents minimal beyond required renames.

### Verification

- Use search to confirm no remaining `CodexWatch`, `CodexUsage`, or `codex-watch` references remain except intentionally preserved historical release notes if needed.
- Run `swift test`.
- Run `swift build`.

## Risks

- SwiftPM target/folder rename can break imports if any reference missed.
- Historical docs may intentionally mention old names, but request says everything, so old names should be removed unless technically unavoidable.

## Non-Goals

- No branding/logo redesign.
- No GitHub org/repo rename outside repository contents.
- No commit yet.

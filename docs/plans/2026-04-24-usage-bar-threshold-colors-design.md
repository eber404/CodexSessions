# Usage Bar Threshold Colors Design

## Goal

Update usage progress bars so color communicates risk level: green below 80%, orange from 80% to 89%, red from 90% to 100%.

## Requirements

1. Thresholds use displayed usage semantics, not remaining quota.
2. Boundaries are:
   - `0-79%` green
   - `80-89%` orange
   - `90-100%` red
3. Change should affect usage bar itself.
4. Keep current layout and copy unless needed.

## Chosen Approach

Keep existing `ProgressView` and drive its `.tint(...)` from a small threshold mapping helper based on `window.usedRatio`.

## Alternatives Considered

### 1. Replace `ProgressView` with custom bar

Rejected. More code, more visual risk, no need for current scope.

### 2. Color only usage text

Rejected. User asked for bar behavior specifically.

### 3. Chosen: tint current `ProgressView`

Accepted. Smallest correct change and easy to verify.

## Design

### UI Behavior

- `ProgressView` remains in `MenuContentView.windowRow(_:)`.
- Add helper that maps `Double` ratio to `Color`.
- Apply helper with `.tint(usageColor(for: ratio))`.

### Threshold Mapping

- `ratio < 0.80` -> green
- `ratio >= 0.80 && ratio < 0.90` -> orange
- `ratio >= 0.90` -> red
- Clamp behavior relies on current `usedRatio`; no extra normalization unless needed.

### Testing

- Extract threshold logic into testable helper if needed.
- Add tests around exact boundaries: `0.79`, `0.80`, `0.89`, `0.90`, `1.0`.
- Verify `swift test` and `swift build`.

## Non-Goals

- No redesign of menu layout.
- No color changes to text/icon unless naturally required later.
- No animation/style overhaul.

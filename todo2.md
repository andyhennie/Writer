# Title Bar Hide/Show Implementation Approaches

## Approaches Tried

### 1. Basic Title Bar Toggle
- **What**: Simple `titlebarAppearsTransparent` and `titleVisibility` toggle
- **Issue**: Window content area shrinks when title bar is hidden, causing visual jump

### 2. Adding Top Padding Compensation
- **What**: Added 28px spacer at top when title bar hidden to compensate for lost space
- **Issue**: Content still jumps down, padding approach doesn't solve the core window sizing issue

### 3. Window Frame Expansion (Downward)
- **What**: Expand window height downward by title bar height when hiding
- **Issue**: Window grows larger than original size, not maintaining total window bounds

### 4. Window Frame with Position Adjustment (Upward Movement)
- **What**: Move window up by title bar height and expand height to maintain content position
- **Issue**: Window moves up on screen, changing its position relative to other windows

### 5. Maintain Total Size with Position Adjustment
- **What**: Keep same window height, only adjust Y position up/down by title bar height
- **Issue**: Window "pops" up and down on screen, changing its absolute position

### 6. Height Compensation with Position
- **What**: Shrink height by title bar amount and move up to maintain total window bounds
- **Issue**: Content area gets smaller instead of larger, defeating the purpose

### 7. Pure Toggle (Current)
- **What**: Only toggle title bar properties without any frame manipulation
- **Result**: Let macOS handle the natural behavior

## Potential Approaches to Try

### 8. Pre-calculate and Store Original Frame
- Store window frame before any title bar changes
- Restore exact frame when toggling back
- May help with precise positioning

### 9. Use Window Delegate Methods
- Implement `NSWindowDelegate` methods like `windowWillResize` or `windowDidResize`
- Override automatic frame adjustments during title bar changes

### 10. Custom Window Subclass
- Create custom `NSWindow` subclass with overridden frame calculation methods
- More control over how window responds to style mask changes

### 11. Delayed Frame Adjustment
- Apply title bar changes first
- Use `DispatchQueue.main.async` to adjust frame after style changes settle
- May avoid timing conflicts with macOS automatic adjustments

### 12. Use `.unified` Title Bar Style
- Try `window.titlebarAppearsTransparent = true` with `.unified` style
- Different approach to title bar integration

### 13. Content View Margin Adjustment
- Instead of window frame changes, adjust content view margins/padding
- Keep window frame constant, only change internal layout

### 14. Save/Restore Content Scroll Position
- Track text editor scroll position before toggle
- Restore exact scroll position after toggle to minimize visual disruption

### 15. Baseline Frame Capture (Current Issue)
- **What**: Capture window frame before first hide, restore to it when showing
- **Issue**: First hide perfect, first show perfect, then growing/shrinking begins
- **Problem**: Baseline captured at wrong time or frame restoration interferes with natural flow

### 16. Two-Phase Approach (Next to Try)
- **What**: Let first hide/show cycle happen naturally, only intervene after
- **Logic**: Since first two operations are perfect, capture "good" state after first show
- **Implementation**: Skip frame manipulation for first cycle, capture baseline after first show completes

### 17. Content-Area Based Approach  
- **What**: Calculate based on content area rather than window frame
- **Logic**: Title bar changes affect content area, work with that instead of total frame

### 18. State Machine Approach
- **What**: Track operation count and behavior differently for each phase
- **States**: Initial (let natural), Post-first-cycle (intervene), Stable (maintain)

## Current Status - NEW FINDINGS
- First hide: ✅ Perfect (natural macOS behavior)
- First show: ✅ Perfect (baseline restoration works)
- Second hide: ❌ Shrinks by title bar height
- Second show: ❌ Grows by title bar height
- **Key insight**: Problem starts after first successful hide/show cycle

## Root Cause Analysis
The issue appears to be that:
1. Our baseline capture includes title bar area incorrectly
2. Or the window state after first restoration is corrupted
3. Or we're interfering with macOS's natural second-cycle behavior
4. The "perfect" frame might be the one AFTER first show, not before first hide

## Notes
- macOS calculates window position from bottom-left corner
- Title bar height ≈ 28px on modern macOS
- `fullSizeContentView` style mask affects how content area is calculated
- **First two operations work perfectly - preserve this behavior**
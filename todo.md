# TextEditor Padding Implementation TODO

## Goal
Add padding inside the TextEditor (top, left, right - no bottom) while keeping the scrollbar at the very edge of the window.

## Approaches Tried

### 1. Direct padding modifiers ❌ FAILED
- Used `.padding(.horizontal)` and `.padding(.top)` on TextEditor
- Result: Added padding between scrollbar and window edge (unwanted)
- Issue: SwiftUI padding affects the entire view including scrollbar positioning

### 2. GeometryReader with offset ❌ FAILED
- Used GeometryReader to manually position TextEditor with offset
- Issue: Will likely break scrollbar positioning and text selection

### 3. scrollContentBackground with custom background ❌ FAILED
- Used `.scrollContentBackground(.hidden)` with custom background Rectangle
- Background has padding, TextEditor stays full width
- Issue: Only creates visual background, doesn't move text content

### 4. Text binding manipulation ❌ FAILED
- Added spaces to beginning of each line in binding getter
- Removed spaces in binding setter
- Result: Creates visual left padding, scrollbar stays at edge
- Issues: Interferes with text editing, cursor behavior, selection

### 5. NSViewRepresentable with NSTextView ✅ SUCCESS
- Created custom PaddedTextEditor using NSViewRepresentable
- Direct access to NSTextView's textContainerInset property
- textContainerInset = NSSize(width: 16, height: 8) for left/right: 16pt, top/bottom: 8pt
- Result: Native text editing behavior preserved, scrollbar at edge
- Perfect UX: no compromises in text editing functionality

## Approaches to Try

### 2. Text binding with padding characters
- Modify the text binding to add spaces/newlines to simulate padding
- Pros: Keeps scrollbar at edge
- Cons: May interfere with text editing, affects actual content

### 3. Overlay/background approach
- Use background or overlay with insets to create visual padding
- TextEditor stays full width, content appears padded

### 4. Custom text container
- Wrap TextEditor in a container with clipped bounds
- Use negative margins or positioning

### 5. textFieldStyle or custom styling
- Investigate TextEditor-specific styling options
- May need to use NSTextView directly

### 6. GeometryReader with manual positioning
- Calculate exact positioning to keep scrollbar at edge
- Manually position TextEditor content area

### 7. ZStack with invisible spacers
- Layer invisible spacers to push content inward
- Keep TextEditor at full width

## Notes
- Scrollbar MUST stay at window edge
- No bottom padding needed
- Top, left, right padding required
- Text content should appear indented but scrollbar unaffected
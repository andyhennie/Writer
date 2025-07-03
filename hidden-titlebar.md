# Hidden Titlebar Technical Documentation

## Overview
This document provides a comprehensive technical overview of how the hidden titlebar functionality is implemented in the Writer macOS application using Swift/SwiftUI.

## Core Implementation

### Location
The hidden titlebar functionality is implemented in `/Users/andreas/Coding/Writer/Writer/ContentView.swift`, specifically in the `toggleTitleBar()` method (lines 73-105).

### State Management
```swift
@State private var isTitleBarHidden = false        // Tracks titlebar visibility state
@State private var originalWindowBackground: NSColor?  // Preserves original window background
@State private var didConfigureWindow = false      // Prevents duplicate window configuration
```

## Technical Architecture

### 1. Window Configuration Setup
```swift
func configureWindowIfNeeded() {
    guard let window = NSApplication.shared.keyWindow,
          !didConfigureWindow else { return }
    
    window.styleMask.insert(.fullSizeContentView)
    didConfigureWindow = true
}
```

**Purpose**: Sets up the window with full-size content view mode to prevent resize issues when toggling the titlebar.

### 2. Titlebar Toggle Mechanism

#### Hiding the Titlebar
```swift
// Make titlebar transparent and hide title
window.titlebarAppearsTransparent = true
window.titleVisibility = .hidden

// Hide all standard window buttons
window.standardWindowButton(.closeButton)?.isHidden = true
window.standardWindowButton(.miniaturizeButton)?.isHidden = true
window.standardWindowButton(.zoomButton)?.isHidden = true

// Hide toolbar
window.toolbar?.isVisible = false

// Customize window appearance
window.backgroundColor = NSColor.clear
window.isOpaque = false
```

#### Showing the Titlebar
```swift
// Restore titlebar opacity and title
window.titlebarAppearsTransparent = false
window.titleVisibility = .visible

// Show all standard window buttons
window.standardWindowButton(.closeButton)?.isHidden = false
window.standardWindowButton(.miniaturizeButton)?.isHidden = false
window.standardWindowButton(.zoomButton)?.isHidden = false

// Show toolbar
window.toolbar?.isVisible = true

// Restore original window background
window.backgroundColor = originalWindowBackground
window.isOpaque = true
```

### 3. SwiftUI Integration

#### UI Toggle Button
```swift
Button(isTitleBarHidden ? "Show" : "Hide") {
    toggleTitleBar()
}
```

#### Conditional View Modifier
```swift
.applyIf(isTitleBarHidden) { $0.ignoresSafeArea(.container, edges: .top) }
```

#### Custom View Modifier Extension
```swift
extension View {
    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
```

## Key NSWindow Properties Used

| Property | Purpose |
|----------|---------|
| `titlebarAppearsTransparent` | Controls titlebar transparency |
| `titleVisibility` | Shows/hides window title |
| `standardWindowButton(_:)` | Access to window control buttons (close, minimize, zoom) |
| `toolbar?.isVisible` | Toolbar visibility control |
| `backgroundColor` | Window background color |
| `isOpaque` | Window opacity setting |
| `styleMask.insert(.fullSizeContentView)` | Prevents window resizing issues |

## Platform-Specific Implementation

### macOS-Specific Features
- **AppKit Integration**: Uses `NSApplication.shared.keyWindow` for window access
- **Native APIs**: Leverages macOS-specific window management APIs
- **Color Management**: Uses `NSColor` for proper color handling
- **Window Buttons**: Direct access to standard macOS window controls

### Safety and Error Handling
```swift
guard let window = NSApplication.shared.keyWindow else { return }
```
- Guard statements prevent crashes when window is unavailable
- Original window background is preserved for restoration
- One-time window configuration prevents duplicate setup

## Implementation Benefits

1. **Seamless Toggle**: No window resizing or visual artifacts during transitions
2. **State Preservation**: Original window properties are preserved and restored
3. **Clean Integration**: Works within SwiftUI's declarative paradigm
4. **Platform Native**: Uses native macOS APIs for proper system behavior
5. **Error Resilient**: Gracefully handles edge cases and missing windows

## Testing and Development

### Monitoring Script
A Python monitoring script (`monitor_window.py`) was created for development testing:
- Tracks window dimension changes in real-time
- Provides feedback on titlebar toggle behavior
- Helps validate that no unwanted resizing occurs

### Recent Improvements (Commit 8a5338b)
- Replaced complex frame tracking with efficient state management
- Improved window background handling
- Added conditional view modifier for better layout control
- Removed verbose logging and debugging code
- Streamlined toggle logic for better performance

## Usage Example

```swift
// In your SwiftUI view
struct ContentView: View {
    @State private var isTitleBarHidden = false
    @State private var originalWindowBackground: NSColor?
    @State private var didConfigureWindow = false
    
    var body: some View {
        VStack {
            Button(isTitleBarHidden ? "Show" : "Hide") {
                toggleTitleBar()
            }
            
            // Your content here
        }
        .applyIf(isTitleBarHidden) { $0.ignoresSafeArea(.container, edges: .top) }
        .onAppear {
            configureWindowIfNeeded()
        }
    }
    
    private func toggleTitleBar() {
        // Implementation as shown above
    }
}
```

## Conclusion

This implementation provides a robust, native macOS experience for toggling titlebar visibility while maintaining the application's visual consistency and user experience. The solution leverages SwiftUI's declarative nature combined with AppKit's powerful window management capabilities to create a seamless user interface enhancement.
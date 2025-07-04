# Titlebar Implementation Documentation

## Overview

The Writer app implements a sophisticated titlebar management system that allows users to hide and show the window titlebar dynamically. The implementation spans multiple files and provides a polished user experience with hover reveals, keyboard shortcuts, and persistent state management.

## Architecture

### Core Components

1. **WindowController.swift** - The main engine that handles NSWindow titlebar configuration
2. **ContentView.swift** - SwiftUI view that manages titlebar state and user interactions
3. **WriterApp.swift** - App-level menu commands and shared state management
4. **DocumentContentView.swift** - Document-specific titlebar handling
5. **WindowAccessor.swift** - Utility for early window access

### Design Philosophy

The implementation follows these principles:

- **User Control**: Users can toggle titlebar visibility with ⌘T or menu commands
- **Discoverability**: Hover reveals help users understand the hidden titlebar
- **Focus Preservation**: Keyboard actions maintain text editor focus
- **Persistence**: Titlebar state is maintained across window operations
- **Robustness**: Handles AppKit's tendency to recreate UI elements

## Key Features

### 1. Toggle Functionality (`⌘T`)

**Implementation**: ContentView.swift:73-86, WriterApp.swift:39-53

The primary feature allows users to hide/show the titlebar:

```swift
// State management
@State private var isTitleBarHidden = false

// Toggle function with focus preservation
func toggleTitleBar() {
    let currentFirstResponder = NSApp.keyWindow?.firstResponder
    isTitleBarHidden.toggle()
    TitleBarState.shared.isHidden = isTitleBarHidden
    
    if let window = NSApp.keyWindow {
        WindowController.shared.setTitleBar(hidden: isTitleBarHidden, for: window)
    }
    
    // Restore focus to maintain user workflow
    if let responder = currentFirstResponder {
        NSApp.keyWindow?.makeFirstResponder(responder)
    }
}
```

**Why**: This approach preserves the user's current focus state while changing the UI, preventing jarring interruptions to the writing experience.

### 2. Hover Reveal System

**Implementation**: ContentView.swift:112-125

```swift
// 50px trigger zone at top of window
private func handleMouseMove(event: NSEvent) {
    let mouseLocation = event.locationInWindow
    let shouldReveal = mouseLocation.y > (NSApp.keyWindow?.frame.height ?? 0) - 50
    
    if shouldReveal && !hoverRevealed && isTitleBarHidden {
        hoverRevealed = true
        if let window = NSApp.keyWindow {
            WindowController.shared.setTitleBar(hidden: false, for: window)
        }
    }
}
```

**Why**: The 50px trigger zone provides a generous target area while avoiding accidental reveals during normal typing. This creates a discoverable interface that doesn't interfere with content creation.

### 3. Keyboard Dismissal

**Implementation**: ContentView.swift:127-148

```swift
private func handleKeyDown(event: NSEvent) {
    if hoverRevealed && isTitleBarHidden {
        hoverRevealed = false
        if let window = NSApp.keyWindow {
            WindowController.shared.setTitleBar(hidden: true, for: window)
        }
    }
    return event
}
```

**Why**: Automatically hides the hover-revealed titlebar when the user starts typing, maintaining the distraction-free writing environment while preserving the user's intent to hide the titlebar.

### 4. Advanced View Suppression

**Implementation**: WindowController.swift:104-195

The most complex part of the implementation deals with AppKit's tendency to recreate titlebar views:

```swift
// Aggressive view suppression to prevent AppKit recreation
private func suppressTitleBarViews(in window: NSWindow) {
    guard let contentView = window.contentView else { return }
    
    // Find and hide all titlebar-related views
    suppressViewsRecursively(in: contentView)
    
    // Store references to restore later
    for subview in contentView.subviews {
        if shouldSuppressView(subview) {
            suppressedViews.append(subview)
            subview.isHidden = true
        }
    }
}
```

**Why**: AppKit frequently recreates titlebar elements during window operations. This aggressive suppression ensures consistent behavior across all user interactions and system events.

### 5. Window Event Handling

**Implementation**: WindowController.swift:283-349

```swift
// Reapply titlebar hiding when window gains focus
func windowDidBecomeKey(_ notification: Notification) {
    guard let window = notification.object as? NSWindow else { return }
    
    if TitleBarState.shared.isHidden {
        setTitleBar(hidden: true, for: window)
    }
}
```

**Why**: macOS window management can restore titlebar visibility during focus changes. This ensures the user's preference persists across all window operations.

## Technical Implementation Details

### State Management

**Global State**: `TitleBarState.shared` singleton maintains app-wide titlebar preference
**Local State**: Each view maintains its own state for immediate UI updates
**Notification System**: Uses `NSNotification` for cross-component communication

### Window Configuration

```swift
// Core window setup for titlebar control
window.styleMask.insert(.fullSizeContentView)
window.titlebarAppearsTransparent = true
window.toolbarStyle = .unifiedCompact
```

**Why**: `.fullSizeContentView` allows content to extend under the titlebar area, while `titlebarAppearsTransparent` creates a seamless appearance. The unified toolbar style provides better visual integration.

### View Identification Strategy

The implementation uses sophisticated view identification to distinguish titlebar elements:

```swift
private func shouldSuppressView(_ view: NSView) -> Bool {
    let className = NSStringFromClass(type(of: view))
    
    // Target specific AppKit titlebar components
    return className.contains("Titlebar") || 
           className.contains("WindowTitle") ||
           className.hasPrefix("NS") && className.contains("Title")
}
```

**Why**: This approach targets specific AppKit internal views without breaking when Apple updates their internal class names.

## User Experience Design

### Discoverability

- **Visual Cues**: Hover reveals provide immediate feedback
- **Keyboard Shortcuts**: Standard macOS ⌘T shortcut for toggle
- **Menu Integration**: View menu provides discoverable access

### Performance Considerations

- **Lazy Configuration**: Window setup only occurs when needed
- **Event Filtering**: Mouse tracking only active when titlebar is hidden
- **Focus Preservation**: Minimal responder chain disruption

### Edge Cases Handled

1. **Full-Screen Transitions**: Proper titlebar restoration when exiting full-screen
2. **Multi-Window Support**: Each window maintains independent titlebar state
3. **App Deactivation**: Titlebar state preserved when app loses focus
4. **System Events**: Robust handling of macOS system-level window changes

## Future Considerations

### Potential Enhancements

1. **User Preferences**: Persistent titlebar preference across app launches
2. **Animation**: Smooth transitions for titlebar show/hide operations
3. **Accessibility**: VoiceOver support for titlebar state changes
4. **Touch Bar**: Integration with MacBook Pro Touch Bar controls

### Known Limitations

1. **AppKit Dependencies**: Relies on undocumented AppKit behavior for view suppression
2. **System Updates**: May require updates when Apple changes internal window management
3. **Performance**: Mouse tracking adds minimal overhead when titlebar is hidden

## Debugging and Maintenance

### Common Issues

1. **View Recreation**: If titlebar reappears unexpectedly, check `suppressTitleBarViews()`
2. **Focus Loss**: Ensure `makeFirstResponder()` calls are properly balanced
3. **State Sync**: Verify notification system is properly connected

### Testing Strategies

1. **Multi-Window**: Test with multiple document windows open
2. **Focus Changes**: Verify behavior when switching between apps
3. **Full-Screen**: Test entering/exiting full-screen mode
4. **System Events**: Test with macOS system-level window operations

This implementation represents a sophisticated approach to titlebar management that balances user control, discoverability, and system integration while maintaining the focus on distraction-free writing.
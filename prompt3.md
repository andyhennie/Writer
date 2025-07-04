# Writer App Titlebar Styling Requirements

## Current Issue
The macOS Writer app has inconsistent titlebar appearance:
- **At launch**: Titlebar appears gray/default system color
- **After hide/show toggle**: Titlebar appears white (desired behavior)

## Required Behavior
The titlebar should be **white** (or fully transparent showing white background) consistently:
1. **On first app launch** - titlebar should be white immediately
2. **After hide/show toggles** - titlebar should remain white
3. **When window gains/loses focus** - titlebar should stay white
4. **When entering/exiting fullscreen** - titlebar should be white when restored

## Technical Context
- **App**: macOS SwiftUI text editor using AppKit window management
- **Key files**: 
  - `WindowController.swift` - handles titlebar styling via `configure()` and `setTitleBar()`
  - `DocumentContentView.swift` - calls window configuration on `onAppear`
- **Current approach**: Uses `titlebarAppearsTransparent = true` + `backgroundColor = NSColor.white`
- **Problem**: AppKit initializes titlebar elements asynchronously, causing timing issues

## Constraints
- Must work with existing titlebar hide/show functionality
- Should not break window dragging or standard window controls
- Must be compatible with macOS 14.0+
- Should handle window lifecycle events (focus, fullscreen, etc.)

## Success Criteria
Titlebar appears white consistently across all scenarios without any gray flashing or timing-dependent behavior.
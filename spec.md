# macOS Title Bar Suppression Issue - Remaining Gray Line

## Problem Summary
A macOS SwiftUI app called "Writer" that has a hidden title bar mode. The app successfully hides the white title bar area, but **a gray line separator still appears at the top of the window** when the window loses and regains focus.

## Current Status
- ✅ White title bar area is now properly suppressed
- ❌ Gray line separator still persists at the top edge when switching apps

## What I Want
**Complete elimination of the gray line that appears at the top of the window when the app loses focus and regains it.**

The app should have:
1. **Perfect hidden title bar mode** - no visual artifacts at all
2. **Hover-to-reveal functionality** - 50px band at top reveals title bar on hover
3. **⌘T hotkey toggle** - switches between hidden/visible title bar modes
4. **No gray line** - the most critical remaining issue

## Technical Context
- **App**: macOS SwiftUI app with NSWindow manipulation
- **Architecture**: Uses WindowController.swift with NSWindowDelegate + ContentView.swift
- **Current Implementation**: Aggressive view suppression that catches white containers but misses the gray line
- **Target**: macOS 14 (Sonoma) compatibility

## The Gray Line Issue
The gray line appears to be a border/separator that's either:
1. Part of a title bar view we're not detecting
2. A window border property that needs separate handling
3. A visual effect view with a border that our detection misses

## Files Involved
- `/Users/andreas/Coding/Writer/Writer/WindowController.swift` - Main title bar suppression logic
- `/Users/andreas/Coding/Writer/Writer/ContentView.swift` - UI and event handling

## Current Detection Logic
The app now aggressively suppresses views that:
- Touch the top edge (within 1px) and are ≥200px wide
- Contain "Titlebar" in class name
- Are NSVisualEffectView positioned at top
- Are plain NSView containers at title bar position

**Need**: Enhanced detection to catch whatever is creating the gray line separator
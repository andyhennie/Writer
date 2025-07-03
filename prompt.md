# Prompt: Fixing macOS hidden-title-bar strip in SwiftUI / AppKit hybrid

## Context

We have a macOS SwiftUI app (`Writer`). It uses a single window that toggles between:

1. **Show mode** – regular title bar visible.
2. **Hide mode** – title bar fully hidden, window content flush to top.  
   • User can hover within 50 px of the top edge to temporarily reveal the bar.  
   • First key-press hides it again.

The implementation manipulates `NSWindow` directly:

```swift
window.styleMask.insert(.fullSizeContentView)
window.setTitleBar(hidden: true) // custom helper that hides buttons & toolbar
window.toolbarStyle = .unifiedCompact // set only in Hide mode
```

It works while the window stays key, **but** when the app loses focus and then becomes key again a 22-px blank gray strip re-appears at the top. Hover-reveal still works, meaning AppKit recreated the title-bar container view even though we tried to collapse it.

Attempts tried so far (and failed):

- Forcing `.fullSizeContentView` + `titlebarAppearsTransparent` every activation.
- Making the window/background clear and drawing our own white background.
- Recursively hiding any `NSVisualEffectView` added by AppKit.
- Re-applying `setTitleBar(hidden:)` in `didBecomeActive` & `didResignActive` notifications.

We're looking for a **bullet-proof** solution that keeps the top strip gone across all focus changes.

## Constraints

- Must work on macOS 14 (Sonoma) and ideally 13.
- App is SwiftUI-first but we're fine dropping down to AppKit.
- Hover-to-reveal behaviour (50 px band) and hot-key (⌘T) must survive.
- No scroll-jumping: content view height must stay constant.

## What you should provide
Solve it. 
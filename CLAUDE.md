# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **macOS-focused Swift/SwiftUI application** that provides a basic plain text editor. The app focuses on macOS (iOS is not important) and offers simple text editing capabilities without formatting, file saving, or sidebar features.

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project Writer.xcodeproj -scheme Writer -configuration Debug build

# Run unit tests
xcodebuild test -project Writer.xcodeproj -scheme Writer -destination 'platform=iOS Simulator,name=iPhone 15'

# Run on macOS
xcodebuild test -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS'

# Run UI tests
xcodebuild test -project Writer.xcodeproj -scheme Writer -testPlan WriterUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Testing
- Unit tests: `WriterTests/` directory using Swift Testing framework
- UI tests: `WriterUITests/` directory using XCTest framework
- Both test suites can be run through Xcode's test navigator or command line

## Architecture

### Core Components
- **WriterApp.swift**: App entry point with SwiftData model container configuration
- **ContentView.swift**: Main UI using NavigationSplitView for master-detail interface
- **Item.swift**: SwiftData model representing timestamped items

### Data Layer
- **SwiftData** for local persistence with CloudKit integration
- **CloudKit** sync configured for development environment
- Model container uses persistent storage (not in-memory)

### UI Architecture
- **SwiftUI** declarative UI with platform-specific adaptations
- **NavigationSplitView** provides master-detail layout
- **@Query** property wrapper for reactive data fetching
- Platform-specific toolbar configurations for iOS vs macOS

### Key Features
- Cross-platform compatibility (iOS, macOS, visionOS)
- CloudKit synchronization with push notifications
- App sandboxing for security
- Automatic state management via SwiftUI

## Platform Support
- **iOS**: 18.5+
- **macOS**: 14.0+
- **visionOS**: 2.5+
- Bundle ID: `com.example.WriterTextEditor`
- Development Team: XB23VLA9H3

## Project Structure
```
Writer/
├── Writer.xcodeproj/          # Xcode project
├── Writer/                    # Main app source
│   ├── WriterApp.swift        # App entry point
│   ├── ContentView.swift    # Main UI
│   ├── Item.swift          # Data model
│   ├── Assets.xcassets/     # App assets
│   ├── Writer.entitlements   # App capabilities
│   └── Info.plist          # App configuration
├── WriterTests/              # Unit tests
└── WriterUITests/            # UI tests
```

## Key Configuration Files
- **Writer.entitlements**: CloudKit, push notifications, app sandbox
- **Info.plist**: Background modes for remote notifications
- **project.pbxproj**: Multi-platform target configuration with file system synchronization
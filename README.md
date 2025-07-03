# Building

## What is Writer?

  ✅ Easiest for development
  - Upload to App Store Connect (no review needed for TestFlight)
  - Install TestFlight app, get invite link
  - Auto-updates, works across devices
  - 90-day builds (can refresh)

  2. Direct Installation (Development)

  ✅ Immediate, no upload needed
  # Build for your Mac
  xcodebuild -project Writer.xcodeproj -scheme Writer -configuration Release
  -derivedDataPath ./build

  # Copy to Applications
  cp -r ./build/Build/Products/Release/Writer.app /Applications/
  ⚠️ Limitations: Expires in ~7 days (free developer account) or 1 year
  (paid)

  3. Archive & Export

  ✅ Professional approach
  1. Xcode → Product → Archive
  2. Distribute App → Developer ID (for personal use)
  3. Export & install the .app
  4. Requires paid Apple Developer account ($99/year)

  4. Self-Signed Distribution

  ✅ Free alternative
  # Build release version
  xcodebuild -project Writer.xcodeproj -scheme Writer -configuration Release

  # Sign with your development certificate
  codesign --force --deep --sign "Your Developer ID" Writer.app

  # Create installer package (optional)
  pkgbuild --component Writer.app --install-location /Applications Writer.pkg

  Recommendation:
  Use TestFlight - it's designed exactly for this use case (personal/internal app distribution without public App Store review).
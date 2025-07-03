#!/bin/bash

echo "🔨 Building Writer app..."
echo ""

# Build the project, suppressing verbose output
xcodebuild -project Writer.xcodeproj -scheme Writer -configuration Release clean build 2>&1 | \
while IFS= read -r line; do
    if [[ "$line" == *"BUILD SUCCEEDED"* ]]; then
        echo "✅ Build completed successfully"
        break
    elif [[ "$line" == *"BUILD FAILED"* ]]; then
        echo "❌ Build failed"
        echo "$line"
        exit 1
    elif [[ "$line" == *"Compiling"* ]] || [[ "$line" == *"Linking"* ]] || [[ "$line" == *"Processing"* ]]; then
        echo "⚙️  $line"
    elif [[ "$line" == *"error:"* ]] || [[ "$line" == *"warning:"* ]]; then
        echo "$line"
    fi
done

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo ""

# Find the built app in DerivedData
APP_PATH="$(find ~/Library/Developer/Xcode/DerivedData -name "Writer.app" -path "*/Release/*" | head -1)"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found in DerivedData"
    echo "Looking in: $APP_PATH"
    exit 1
fi

echo "📍 Found app at: $APP_PATH"

echo "📦 Installing to /Applications..."

# Remove existing app if it exists
if [ -d "/Applications/Writer.app" ]; then
    echo "🗑️  Removing existing Writer.app from Applications"
    rm -rf "/Applications/Writer.app"
fi

# Copy the new app
cp -R "$APP_PATH" "/Applications/"

if [ $? -eq 0 ]; then
    echo "🎉 Writer.app successfully installed to /Applications"
else
    echo "❌ Failed to install Writer.app"
    exit 1
fi

#!/bin/bash

set -e

echo "🧪 Running tests..."

xcodebuild test \
    -project TimeCapsule.xcodeproj \
    -scheme TimeCapsule \
    -destination 'platform=macOS' \
    -quiet

echo "✅ All tests passed!"

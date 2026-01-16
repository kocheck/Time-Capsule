#!/bin/bash

set -e

echo "🚀 Setting up Time Capsule development environment..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Install SwiftLint if not installed
if ! command -v swiftlint &> /dev/null; then
    echo "📦 Installing SwiftLint..."
    brew install swiftlint
else
    echo "✅ SwiftLint already installed"
fi

# Install xcbeautify for better build output (optional)
if ! command -v xcbeautify &> /dev/null; then
    echo "📦 Installing xcbeautify..."
    brew install xcbeautify
else
    echo "✅ xcbeautify already installed"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Open TimeCapsule.xcodeproj in Xcode"
echo "  2. Build and run the project (⌘R)"
echo "  3. Or use 'make build' to build from command line"

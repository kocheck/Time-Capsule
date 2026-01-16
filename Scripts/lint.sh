#!/bin/bash

set -e

echo "🔍 Running SwiftLint..."

if ! command -v swiftlint &> /dev/null; then
    echo "❌ SwiftLint not found. Please run 'make setup' first."
    exit 1
fi

swiftlint lint --strict

echo "✅ Linting passed!"

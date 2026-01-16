#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              TIME CAPSULE - LINT STAGED FILES ONLY                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Get staged Swift files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep "\.swift$" || true)

if [ -z "$STAGED_FILES" ]; then
    echo "✓ No Swift files staged for commit"
    exit 0
fi

echo "🔍 Linting staged files..."
echo ""

# Create temp file with staged files list
TEMP_FILE=$(mktemp)
echo "$STAGED_FILES" > "$TEMP_FILE"

# Run SwiftLint on staged files only
FAILED=false

while IFS= read -r file; do
    if [ -f "$file" ]; then
        echo -n "  $file... "

        # Lint single file
        OUTPUT=$(swiftlint lint --path "$file" --config .swiftlint.yml --quiet 2>&1 || true)

        if [ -n "$OUTPUT" ]; then
            echo "❌"
            echo "$OUTPUT" | head -5
            FAILED=true
        else
            echo "✓"
        fi
    fi
done < "$TEMP_FILE"

rm "$TEMP_FILE"

echo ""
if [ "$FAILED" = true ]; then
    echo "❌ Linting failed. Please fix issues before committing."
    echo ""
    echo "Run './Scripts/lint.sh --fix' to auto-fix some issues."
    exit 1
else
    echo "✅ All staged files passed linting!"
    exit 0
fi

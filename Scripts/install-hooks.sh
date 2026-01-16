#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              TIME CAPSULE - INSTALL GIT HOOKS                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "🔧 Installing Git hooks..."

# Create hooks directory if needed
mkdir -p "$HOOKS_DIR"

# Install pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/usr/bin/env bash
set -e

echo "🔍 Running pre-commit checks..."

# Ensure scripts are executable
chmod +x ./Scripts/*.sh 2>/dev/null || true

# Run staged file linter
./Scripts/lint-staged.sh

# Check for debug code
if git diff --cached --name-only | xargs grep -l "DEBUG_MODE\s*=\s*true" 2>/dev/null; then
    echo "❌ DEBUG_MODE=true found in staged files. Remove before committing."
    exit 1
fi

# Check for focused tests
if git diff --cached --name-only | xargs grep -l "\.focused\|@Test.*focused" 2>/dev/null; then
    echo "❌ Focused tests found in staged files. Remove .focused before committing."
    exit 1
fi

echo "✅ Pre-commit checks passed!"
EOF

chmod +x "$HOOKS_DIR/pre-commit"
echo "  ✓ Installed pre-commit hook"

# Install pre-push hook
cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/usr/bin/env bash
set -e

echo "🔒 Running pre-push security audit..."

# Run full security audit
./Scripts/lint-security.sh

# Run full lint with strict config
./Scripts/lint.sh --strict --quiet

echo "✅ Pre-push checks passed!"
EOF

chmod +x "$HOOKS_DIR/pre-push"
echo "  ✓ Installed pre-push hook"

echo ""
echo "✅ Git hooks installed successfully!"
echo ""
echo "Hooks will run automatically:"
echo "  • pre-commit: Lint staged Swift files"
echo "  • pre-push:   Full security audit + strict lint"

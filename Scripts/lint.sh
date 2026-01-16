#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              TIME CAPSULE - MAIN LINT SCRIPT                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Banner ──
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║            🦖 TIME CAPSULE LINTER                            ║"
echo "║            Security-First • Data-Safe                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Check SwiftLint ──
if ! command -v swiftlint &> /dev/null; then
    echo -e "${RED}❌ SwiftLint not installed.${NC}"
    echo -e "${YELLOW}Installing via Homebrew...${NC}"
    brew install swiftlint
fi

SWIFTLINT_VERSION=$(swiftlint version)
echo -e "${BLUE}SwiftLint version: ${SWIFTLINT_VERSION}${NC}"
echo ""

# ── Parse Arguments ──
MODE="default"
CONFIG=".swiftlint.yml"
FIX=false
QUIET=false
REPORTER="xcode"

print_help() {
    echo "Usage: ./Scripts/lint.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --fix           Auto-fix violations where possible"
    echo "  --strict        Use CI-strict configuration"
    echo "  --tests         Lint only test files with test config"
    echo "  --security      Run security-focused audit only"
    echo "  --quiet         Minimal output"
    echo "  --report        Generate HTML report"
    echo "  --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  ./Scripts/lint.sh                 # Standard lint"
    echo "  ./Scripts/lint.sh --fix           # Auto-fix issues"
    echo "  ./Scripts/lint.sh --strict        # CI-level strictness"
    echo "  ./Scripts/lint.sh --security      # Security audit"
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --fix) FIX=true ;;
        --strict) CONFIG=".swiftlint-strict.yml" ;;
        --tests) CONFIG=".swiftlint-tests.yml" ;;
        --security) MODE="security" ;;
        --quiet) QUIET=true ;;
        --report) REPORTER="html"; REPORT_FILE="lint-report.html" ;;
        --help) print_help; exit 0 ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; print_help; exit 1 ;;
    esac
    shift
done

# ── Security Mode ──
if [ "$MODE" = "security" ]; then
    echo -e "${YELLOW}🔒 Running Security Audit...${NC}"
    echo ""

    SECURITY_PATTERNS=(
        "force_unwrapping"
        "force_try"
        "force_cast"
        "no_unencrypted_storage"
        "no_hardcoded_secrets"
        "no_http_urls"
        "no_print_statements"
        "no_empty_catch"
    )

    FAILED=false

    for pattern in "${SECURITY_PATTERNS[@]}"; do
        echo -ne "  Checking ${pattern}... "
        COUNT=$(swiftlint lint --config "$CONFIG" --quiet 2>/dev/null | grep -c "$pattern" || true)

        if [ "$COUNT" -gt 0 ]; then
            echo -e "${RED}✗ ${COUNT} violation(s)${NC}"
            FAILED=true
        else
            echo -e "${GREEN}✓${NC}"
        fi
    done

    echo ""
    if [ "$FAILED" = true ]; then
        echo -e "${RED}❌ Security audit failed. Fix issues before proceeding.${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ Security audit passed!${NC}"
        exit 0
    fi
fi

# ── Build Command ──
CMD="swiftlint"

if [ "$FIX" = true ]; then
    CMD="$CMD --fix"
    echo -e "${YELLOW}🔧 Auto-fix mode enabled${NC}"
fi

CMD="$CMD lint --config $CONFIG"

if [ "$QUIET" = true ]; then
    CMD="$CMD --quiet"
fi

if [ "$REPORTER" = "html" ]; then
    CMD="$CMD --reporter html > $REPORT_FILE"
    echo -e "${BLUE}📄 Generating HTML report: $REPORT_FILE${NC}"
fi

# ── Run Lint ──
echo -e "${BLUE}Running: $CMD${NC}"
echo ""

eval "$CMD"
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    ✅ LINTING PASSED                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    ❌ LINTING FAILED                          ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Tip: Run './Scripts/lint.sh --fix' to auto-fix some issues${NC}"
fi

exit $EXIT_CODE

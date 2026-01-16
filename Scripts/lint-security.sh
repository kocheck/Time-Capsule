#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              TIME CAPSULE - SECURITY AUDIT SCRIPT                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          🔒 TIME CAPSULE SECURITY AUDIT                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

ISSUES_FOUND=0
REPORT=""

# ── Function to check for pattern ──
check_pattern() {
    local name="$1"
    local pattern="$2"
    local severity="$3"
    local message="$4"

    echo -ne "  Checking: ${name}... "

    MATCHES=$(grep -rn --include="*.swift" -E "$pattern" TimeCapsule/ 2>/dev/null | grep -v "Tests" | grep -v "Preview" || true)
    COUNT=$(echo "$MATCHES" | grep -c "." || echo "0")

    if [ "$COUNT" -gt 0 ] && [ -n "$MATCHES" ]; then
        if [ "$severity" = "error" ]; then
            echo -e "${RED}✗ CRITICAL ($COUNT)${NC}"
            ISSUES_FOUND=$((ISSUES_FOUND + COUNT))
        else
            echo -e "${YELLOW}⚠ WARNING ($COUNT)${NC}"
        fi
        REPORT+="\\n### $name ($COUNT issues)\\n$message\\n\`\`\`\\n$MATCHES\\n\`\`\`\\n"
    else
        echo -e "${GREEN}✓${NC}"
    fi
}

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  CRITICAL SECURITY CHECKS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

check_pattern \
    "Hardcoded Secrets" \
    "(password|secret|token|apiKey|api_key|private_key)\s*[:=]\s*\"[^\"]+\"" \
    "error" \
    "Hardcoded secrets found. Move to Keychain or environment variables."

check_pattern \
    "Unencrypted Storage" \
    "UserDefaults.*(password|token|secret|key|credential)" \
    "error" \
    "Sensitive data in UserDefaults. Use KeychainService instead."

check_pattern \
    "HTTP URLs" \
    "\"http://(?!localhost|127\.0\.0\.1)" \
    "error" \
    "Insecure HTTP URLs found. Use HTTPS."

check_pattern \
    "Force Try" \
    "try!\s" \
    "error" \
    "Force try can crash. Use do-catch."

check_pattern \
    "Force Unwrap" \
    "!\s*$|!\." \
    "error" \
    "Force unwrap can crash. Use optional binding."

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  DATA SAFETY CHECKS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

check_pattern \
    "Print Statements" \
    "\bprint\s*\(" \
    "error" \
    "Print statements can leak data. Use Logger."

check_pattern \
    "NSLog Usage" \
    "\bNSLog\s*\(" \
    "error" \
    "NSLog persists to system log. Use Logger."

check_pattern \
    "Empty Catch Blocks" \
    "catch\s*\{\s*\}" \
    "error" \
    "Empty catch blocks hide errors. Log or handle properly."

check_pattern \
    "Direct FileManager" \
    "FileManager\.default\.(createFile|write)" \
    "warning" \
    "Use DataService for file operations with proper error handling."

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  THREAD SAFETY CHECKS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

check_pattern \
    "Main Thread Sync" \
    "DispatchQueue\.main\.sync" \
    "error" \
    "Sync dispatch to main can deadlock."

check_pattern \
    "Task.detached" \
    "Task\.detached\s*\{" \
    "warning" \
    "Task.detached loses context. Prefer structured concurrency."

echo ""
echo "═══════════════════════════════════════════════════════════════"

if [ $ISSUES_FOUND -gt 0 ]; then
    echo -e "${RED}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║       ❌ SECURITY AUDIT FAILED: $ISSUES_FOUND ISSUE(S)              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Write report
    echo -e "$REPORT" > security-audit-report.md
    echo "Full report written to: security-audit-report.md"
    exit 1
else
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           ✅ SECURITY AUDIT PASSED                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    exit 0
fi

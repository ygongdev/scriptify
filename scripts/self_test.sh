#!/usr/bin/env bash
# Self-test for the scriptify plugin.
# Tests what can be verified deterministically:
#   1. Fixture files exist and are well-formed
#   2. pre-verify.sh passes its own static checks
#   3. Audit report (if present) has the expected JSON schema
#
# LLM-dependent steps (audit, generate, verify) must be run manually
# via /scriptify:audit, /scriptify:generate, /scriptify:verify.

set -euo pipefail

PASS=0; FAIL=0
OVERALL_EXIT=0
AUDIT_REPORT="${SCRIPTIFY_AUDIT_REPORT:-${TMPDIR:-/tmp}/scriptify/audit-report.json}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── colours ────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; RESET='\033[0m'
else
  GREEN=''; RED=''; BOLD=''; RESET=''
fi

pass() { echo -e "  ${GREEN}PASS${RESET}  $*"; ((PASS++)) || true; }
fail() { echo -e "  ${RED}FAIL${RESET}  $*"; ((FAIL++)) || true; OVERALL_EXIT=1; }

echo -e "${BOLD}## Scriptify Self-Test${RESET}"
echo ""

# ── Step 1: Fixture files ──────────────────────────────────────────────────
echo "### Step 1: Fixtures"

FIXTURES=(
  "test/fixtures/skills/example/SKILL.md"
  "test/fixtures/CLAUDE.md"
)

for f in "${FIXTURES[@]}"; do
  if [[ -f "$REPO_ROOT/$f" ]]; then
    pass "Fixture exists: $f"
  else
    fail "Fixture missing: $f"
  fi
done

# Fixture skill has a shebang-style frontmatter description
if grep -q "^description:" "$REPO_ROOT/test/fixtures/skills/example/SKILL.md" 2>/dev/null; then
  pass "Fixture SKILL.md has description frontmatter"
else
  fail "Fixture SKILL.md missing description frontmatter"
fi

echo ""

# ── Step 2: pre-verify.sh static checks ───────────────────────────────────
echo "### Step 2: pre-verify.sh"

PRE_VERIFY="$SCRIPT_DIR/pre-verify.sh"

if [[ -f "$PRE_VERIFY" ]]; then
  pass "scripts/pre-verify.sh exists"
else
  fail "scripts/pre-verify.sh missing"
fi

if [[ -x "$PRE_VERIFY" ]]; then
  pass "scripts/pre-verify.sh is executable"
else
  fail "scripts/pre-verify.sh is not executable"
fi

if bash -n "$PRE_VERIFY" 2>/dev/null; then
  pass "scripts/pre-verify.sh syntax valid"
else
  fail "scripts/pre-verify.sh syntax error: $(bash -n "$PRE_VERIFY" 2>&1)"
fi

# Verify shebang
if [[ "$(head -1 "$PRE_VERIFY")" == "#!"* ]]; then
  pass "scripts/pre-verify.sh has shebang"
else
  fail "scripts/pre-verify.sh missing shebang"
fi

echo ""

# ── Step 3: Audit report schema (if present) ──────────────────────────────
echo "### Step 3: Audit report schema (optional)"

if [[ -f "$AUDIT_REPORT" ]]; then
  if python3 -c "
import json, sys
data = json.load(open('$AUDIT_REPORT'))
assert 'summary' in data, 'missing summary'
assert 'items' in data, 'missing items'
assert isinstance(data['items'], list), 'items must be a list'
for item in data['items']:
    assert 'id' in item, 'item missing id'
    assert 'scriptifiable' in item, 'item missing scriptifiable'
" 2>/dev/null; then
    pass "Audit report schema valid ($AUDIT_REPORT)"
  else
    fail "Audit report schema invalid ($AUDIT_REPORT)"
  fi
else
  echo "  SKIP  No audit report at $AUDIT_REPORT (run /scriptify:audit to generate)"
fi

echo ""

# ── Summary ────────────────────────────────────────────────────────────────
TOTAL=$((PASS + FAIL))
echo "### Summary"
echo "  Passed : $PASS / $TOTAL"
echo "  Failed : $FAIL / $TOTAL"
echo ""

if [[ $OVERALL_EXIT -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}Overall: PASS${RESET}"
else
  echo -e "${RED}${BOLD}Overall: FAIL${RESET}"
fi

echo ""
echo "Note: LLM-dependent steps must be run manually:"
echo "  /scriptify:audit test/fixtures/"
echo "  /scriptify:generate item 1"
echo "  /scriptify:verify all"

exit $OVERALL_EXIT

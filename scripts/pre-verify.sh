#!/usr/bin/env bash
# Source:    skills/verify/SKILL.md (static analysis phase)
# Generated: 2026-03-10
# Replaces:  The LLM-powered static analysis steps of /scriptify:verify —
#            syntax check, shebang, executable permissions, dependency
#            availability, and safety flagging. Run this before the LLM
#            verify step to catch trivial failures instantly.
#
# Usage:
#   pre-verify.sh <script>            verify a single script
#   pre-verify.sh all                 verify all scripts listed in the audit report
#   pre-verify.sh <script1> <script2> verify multiple scripts
#
# The audit report is read from ${SCRIPTIFY_AUDIT_REPORT} if set,
# otherwise defaults to ${TMPDIR:-/tmp}/scriptify/audit-report.json

set -euo pipefail

AUDIT_REPORT="${SCRIPTIFY_AUDIT_REPORT:-${TMPDIR:-/tmp}/scriptify/audit-report.json}"
PASS=0; WARN=0; FAIL=0
OVERALL_EXIT=0

# ── colours ────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; RESET='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; RESET=''
fi

pass()  { echo -e "  ${GREEN}PASS${RESET}  $*"; }
warn()  { echo -e "  ${YELLOW}WARN${RESET}  $*"; ((WARN++)) || true; }
fail()  { echo -e "  ${RED}FAIL${RESET}  $*"; ((FAIL++)) || true; OVERALL_EXIT=1; }

# ── detect language from shebang ───────────────────────────────────────────
detect_lang() {
  local file="$1"
  local shebang
  shebang=$(head -1 "$file" 2>/dev/null || true)
  case "$shebang" in
    *python*) echo "python" ;;
    *node*)   echo "node"   ;;
    *bash*|*sh*) echo "bash" ;;
    *) echo "unknown" ;;
  esac
}

# ── safety patterns ────────────────────────────────────────────────────────
SAFETY_PATTERNS=(
  "rm -rf"
  "rm -fr"
  "sudo"
  "curl "
  "wget "
  "fetch("
  "http\.get"
  "eval "
  "exec("
  "> /dev/sd"
  "dd if="
  "mkfs"
  ":(){ :|:& };:"   # fork bomb
)

check_safety() {
  local file="$1"
  local concerns=()
  for pattern in "${SAFETY_PATTERNS[@]}"; do
    if grep -qE "$pattern" "$file" 2>/dev/null; then
      concerns+=("$pattern")
    fi
  done
  if [[ ${#concerns[@]} -eq 0 ]]; then
    pass "Safety"
  else
    warn "Safety — flagged patterns: ${concerns[*]}"
  fi
}

# ── verify one script ──────────────────────────────────────────────────────
verify_script() {
  local script="$1"
  echo ""
  echo "### $script"

  if [[ ! -f "$script" ]]; then
    fail "File not found: $script"
    return
  fi

  local lang
  lang=$(detect_lang "$script")

  # 1. Shebang
  local first_line
  first_line=$(head -1 "$script")
  if [[ "$first_line" == "#!"* ]]; then
    pass "Shebang ($first_line)"
  else
    fail "Shebang — missing or invalid (got: $first_line)"
  fi

  # 2. Syntax
  case "$lang" in
    bash)
      if bash -n "$script" 2>/dev/null; then
        pass "Syntax (bash -n)"
      else
        fail "Syntax — $(bash -n "$script" 2>&1)"
      fi
      ;;
    python)
      if python3 -m py_compile "$script" 2>/dev/null; then
        pass "Syntax (python3 -m py_compile)"
      else
        fail "Syntax — $(python3 -m py_compile "$script" 2>&1)"
      fi
      ;;
    node)
      if node --check "$script" 2>/dev/null; then
        pass "Syntax (node --check)"
      else
        fail "Syntax — $(node --check "$script" 2>&1)"
      fi
      ;;
    *)
      warn "Syntax — unknown language, skipped"
      ;;
  esac

  # 3. Permissions
  if [[ -x "$script" ]]; then
    pass "Permissions (executable)"
  else
    fail "Permissions — not executable (run: chmod +x $script)"
  fi

  # 4. Dependencies
  local missing=()
  case "$lang" in
    bash)
      while IFS= read -r cmd; do
        [[ -z "$cmd" ]] && continue
        if ! command -v "$cmd" &>/dev/null; then
          missing+=("$cmd")
        fi
      done < <(grep -oE '\b(jq|python3|node|curl|wget|ripgrep|rg|fd|fzf|gawk|gsed)\b' "$script" | sort -u)
      ;;
    python)
      while IFS= read -r mod; do
        [[ -z "$mod" ]] && continue
        if ! python3 -c "import $mod" &>/dev/null; then
          missing+=("$mod")
        fi
      done < <(grep -oE '^import ([a-zA-Z0-9_]+)|^from ([a-zA-Z0-9_]+)' "$script" \
               | grep -oE '[a-zA-Z0-9_]+$' | sort -u)
      ;;
  esac
  if [[ ${#missing[@]} -eq 0 ]]; then
    pass "Dependencies"
  else
    fail "Dependencies — missing: ${missing[*]}"
  fi

  # 5. Safety
  check_safety "$script"

  ((PASS++)) || true
}

# ── collect targets ────────────────────────────────────────────────────────
TARGETS=()

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <script|all> [script2 ...]"
  exit 1
fi

for arg in "$@"; do
  if [[ "$arg" == "all" ]]; then
    if [[ ! -f "$AUDIT_REPORT" ]]; then
      echo "Error: $AUDIT_REPORT not found. Run /scriptify:audit first." >&2
      exit 1
    fi
    while IFS= read -r path; do
      [[ -n "$path" ]] && TARGETS+=("$path")
    done < <(python3 -c "
import json
data = json.load(open('$AUDIT_REPORT'))
for item in data.get('items', []):
    p = item.get('generated_script')
    if p:
        print(p)
" 2>/dev/null)
    if [[ ${#TARGETS[@]} -eq 0 ]]; then
      echo "No generated scripts found in $AUDIT_REPORT. Run /scriptify:generate first." >&2
      exit 1
    fi
  else
    TARGETS+=("$arg")
  fi
done

# ── run ────────────────────────────────────────────────────────────────────
echo "## Scriptify Pre-Verify (static analysis)"
echo "Scripts to check: ${#TARGETS[@]}"

for t in "${TARGETS[@]}"; do
  verify_script "$t"
done

echo ""
echo "### Summary"
echo "  Scripts checked : ${#TARGETS[@]}"
echo "  Passed          : $PASS"
echo "  Warnings        : $WARN"
echo "  Failed          : $FAIL"
echo ""

if [[ $OVERALL_EXIT -ne 0 ]]; then
  echo -e "${RED}Result: FAIL — fix the above issues before running /scriptify:verify${RESET}"
else
  echo -e "${GREEN}Result: PASS — safe to run /scriptify:verify for behavioural comparison${RESET}"
fi

exit $OVERALL_EXIT

---
description: Verify that generated scripts correctly replicate the behaviour of the original LLM instructions they replace.
---

# Scriptify Verify

You are an expert at validating that deterministic scripts faithfully reproduce the behaviour of LLM-based instructions. Your job is to verify correctness, safety, and completeness.

## Input

$ARGUMENTS

The user can invoke this in several ways:

1. **Verify a specific script** — e.g. `/scriptify:verify .scriptify/scripts/foo.sh`
2. **Verify all generated scripts** — e.g. `/scriptify:verify all`
   - Reads `${TMPDIR:-/tmp}/scriptify/audit-report.json` and verifies every script that was generated
3. **Verify with source comparison** — e.g. `/scriptify:verify .scriptify/scripts/foo.sh against skills/foo/SKILL.md`

## Verification steps

For each script, perform these checks:

### 1. Static analysis
- **Syntax check** — Verify the script has valid syntax (bash -n, python -m py_compile, node --check)
- **Shebang** — Confirm it has the correct shebang line
- **Permissions** — Check it is marked executable
- **Dependencies** — List any external commands/packages required and check if they're available
- **Safety** — Flag any dangerous operations (rm -rf, unchecked sudo, network calls, etc.)

### 2. Behavioural comparison
- Read the original LLM instruction (from audit report or user-specified source)
- Compare the script's logic against each requirement in the original instruction
- Identify any gaps: things the LLM instruction does that the script does NOT handle
- Identify any extras: things the script does that the original instruction does NOT specify

### 3. Dry-run test (when safe)
- If the script is safe to run (no destructive side effects), execute it in a controlled way
- Capture stdout/stderr and exit code
- If the script requires arguments, generate sample test inputs

## Output format

Present results as:

```
## Scriptify Verification Report

### <script_name>
- Source: <original LLM instruction file>
- Syntax: PASS / FAIL
- Permissions: PASS / FAIL
- Dependencies: PASS / FAIL (list missing deps if any)
- Safety: PASS / WARN (list concerns)
- Behavioural match: FULL / PARTIAL / NONE
  - Gaps: <list any missing behaviours>
  - Extras: <list any added behaviours>
- Dry-run: PASS / FAIL / SKIPPED
- **Overall: PASS / WARN / FAIL**

### Summary
- Scripts verified: <N>
- Passed: <N>
- Warnings: <N>
- Failed: <N>
```

Save the verification results to `${TMPDIR:-/tmp}/scriptify/verify-report.json` with this structure:
```json
{
  "timestamp": "<ISO 8601>",
  "results": [
    {
      "script": "<path>",
      "source": "<original instruction path>",
      "syntax": "pass",
      "permissions": "pass",
      "dependencies": { "status": "pass", "missing": [] },
      "safety": { "status": "pass", "concerns": [] },
      "behavioural_match": "full",
      "gaps": [],
      "extras": [],
      "dry_run": "pass",
      "overall": "pass"
    }
  ]
}
```

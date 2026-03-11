---
description: Run a self-test of the scriptify plugin to verify all skills (audit, generate, verify) work correctly end-to-end.
---

# Scriptify Self-Test

You are testing the scriptify plugin itself. Run an end-to-end test of all three skills to confirm they work correctly.

## Test fixtures

Pre-baked fixtures live at `test/fixtures/` in the project root:
- `test/fixtures/skills/example/SKILL.md` — a simple, scriptifiable skill (TODO finder)
- `test/fixtures/CLAUDE.md` — a CLAUDE.md with a repeatable instruction section

Do not create or delete fixture files. They are committed to the repo.

## Test procedure

Execute the following steps in order, reporting results as you go:

### Step 1: Test audit
- Run `/scriptify:audit` against `test/fixtures/`
- Verify the audit:
  - Finds the sample skill file
  - Identifies it as scriptifiable
  - Produces a valid JSON report at `${TMPDIR:-/tmp}/scriptify/audit-report.json`
  - Report contains expected fields (`summary`, `items`)
- Report: PASS or FAIL with details

### Step 2: Test generate
- Run `/scriptify:generate item 1` to generate a script from the first audit item
- Verify the generation:
  - Creates a script file in `scripts/`
  - Script has a valid shebang line
  - Script does NOT contain any LLM API calls
  - Script logic matches the original skill's purpose (finding TODOs)
- Report: PASS or FAIL with details

### Step 3: Test verify
- Run `/scriptify:verify all` to verify the generated script(s)
- Verify the verification:
  - Produces a verification report
  - Checks syntax, permissions, safety, and behavioural match
  - Saves results to `${TMPDIR:-/tmp}/scriptify/verify-report.json`
- Report: PASS or FAIL with details

### Step 4: Cleanup
- Remove any scripts generated into `scripts/` during this test run
- Leave `test/fixtures/` untouched

## Output format

```
## Scriptify Self-Test Results

| Step | Test | Status | Details |
|------|------|--------|---------|
| 1 | Audit | PASS/FAIL | ... |
| 2 | Generate | PASS/FAIL | ... |
| 3 | Verify | PASS/FAIL | ... |
| 4 | Cleanup | PASS/FAIL | ... |

**Overall: PASS / FAIL**
<N>/4 tests passed

### Issues found (if any)
- <description of any failures>
```

If any step fails, continue with the remaining steps and report all results at the end. Do not stop on first failure.

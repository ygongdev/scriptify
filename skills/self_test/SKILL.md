---
description: Run a self-test of the scriptify plugin to verify all skills (audit, generate, verify) work correctly end-to-end.
---

# Scriptify Self-Test

You are testing the scriptify plugin itself. Run an end-to-end test of all three skills to confirm they work correctly.

## Test procedure

Execute the following steps in order, reporting results as you go:

### Step 1: Setup
- Create a temporary test fixture directory at `.scriptify/test_fixtures/`
- Inside it, create a sample skill file `skills/example/SKILL.md` with a simple, scriptifiable LLM instruction. For example a skill that lists all TODO comments in the project:

```markdown
---
description: Find all TODO comments in the codebase
---

Search through all source files in the project and find lines containing TODO comments.
For each TODO found, print the file path, line number, and the TODO text.
Sort results by file path.
Output in the format: <file>:<line>: <todo text>
```

- Also create a sample `CLAUDE.md` with a repeatable instruction section

### Step 2: Test audit
- Run `/scriptify:audit` against the test fixture directory `.scriptify/test_fixtures/`
- Verify the audit:
  - Finds the sample skill file
  - Identifies it as scriptifiable
  - Produces a valid JSON report at `.scriptify/audit-report.json`
  - Report contains expected fields (summary, items)
- Report: PASS or FAIL with details

### Step 3: Test generate
- Run `/scriptify:generate item 1` to generate a script from the first audit item
- Verify the generation:
  - Creates a script file in `.scriptify/scripts/`
  - Script has a valid shebang line
  - Script does NOT contain any LLM API calls
  - Script logic matches the original skill's purpose (finding TODOs)
- Report: PASS or FAIL with details

### Step 4: Test verify
- Run `/scriptify:verify all` to verify the generated script(s)
- Verify the verification:
  - Produces a verification report
  - Checks syntax, permissions, safety, and behavioural match
  - Saves results to `.scriptify/verify-report.json`
- Report: PASS or FAIL with details

### Step 5: Cleanup
- Remove the test fixture directory `.scriptify/test_fixtures/`
- Keep the generated reports for inspection

## Output format

```
## Scriptify Self-Test Results

| Step | Test | Status | Details |
|------|------|--------|---------|
| 1 | Setup | PASS/FAIL | ... |
| 2 | Audit | PASS/FAIL | ... |
| 3 | Generate | PASS/FAIL | ... |
| 4 | Verify | PASS/FAIL | ... |
| 5 | Cleanup | PASS/FAIL | ... |

**Overall: PASS / FAIL**
<N>/5 tests passed

### Issues found (if any)
- <description of any failures>
```

If any step fails, continue with the remaining steps and report all results at the end. Do not stop on first failure.

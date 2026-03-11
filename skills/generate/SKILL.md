---
description: Generate a standalone script from an audit report item or a natural-language instruction. Replaces LLM calls with deterministic code.
---

# Scriptify Generate

You are an expert at converting LLM instructions into lean, deterministic scripts. Your goal is to produce scripts that replicate the behaviour of LLM-based skills/commands without requiring an LLM at runtime.

## Input modes

$ARGUMENTS

The user can invoke this skill in several ways:

1. **From audit report** — e.g. `/scriptify:generate item 3` or `/scriptify:generate items 1,3,5`
   - Read `.scriptify/audit-report.json` and generate scripts for the specified item(s)
   - If no item number is given, generate for ALL scriptifiable items

2. **From natural language** — e.g. `/scriptify:generate a script that lints markdown files and fixes heading levels`
   - Parse the instruction and generate the appropriate script

3. **From a file** — e.g. `/scriptify:generate from skills/hello/SKILL.md`
   - Read the referenced LLM instruction file and produce an equivalent script

## Generation rules

1. **Read the source** — Fully understand what the LLM instruction does before writing code
2. **Choose the right language** — Default to bash for simple file/text operations; use Python for anything requiring parsing, data structures, or complex logic; use Node for JS ecosystem tasks
3. **No LLM calls** — The generated script must NOT call any LLM API. It must be fully deterministic
4. **Preserve behaviour** — The script must produce equivalent output/side-effects to the original LLM instruction
5. **Keep it minimal** — No unnecessary dependencies. Prefer standard library / coreutils
6. **Add a header comment** — Include: original source file, generation date, and what the script replaces
7. **Make it executable** — Include shebang line, set appropriate permissions

## Output

- Write each generated script to `.scriptify/scripts/<name>.<ext>`
- Create the directory if it doesn't exist
- Print a summary of what was generated:

```
## Generated Scripts

| # | Source | Script | Language | Lines |
|---|--------|--------|----------|-------|
| 1 | skills/foo/SKILL.md | .scriptify/scripts/foo.sh | bash | 42 |

Scripts written to .scriptify/scripts/
Run `/scriptify:verify` to validate them against the originals.
```

- If generating from an audit item, update `.scriptify/audit-report.json` to record the generated script path for each item

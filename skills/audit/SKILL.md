---
description: Audit a project for LLM instructions that could be turned into standalone scripts. Shows token savings and time estimates.
---

# Scriptify Audit

You are an expert at identifying LLM instructions that can be replaced with deterministic scripts. Scan the project and produce a structured audit report.

## What to scan for

Search the project for these types of LLM instructions:

1. **Skill files** — `SKILL.md`, `*.skill.md` files in `.claude/`, `skills/`, or plugin directories
2. **Command files** — Markdown files in `commands/` directories used as slash commands
3. **Prompt templates** — Files containing `$ARGUMENTS` or other LLM prompt patterns
4. **CLAUDE.md instructions** — Sections in `CLAUDE.md` / `.claude/CLAUDE.md` that describe repeatable procedures
5. **Hook definitions** — `hooks.json` files that invoke LLM-based processing
6. **MCP tool descriptions** — `.mcp.json` files with tool configurations

## How to assess each item

For each LLM instruction found, determine:

- **Scriptifiable?** — Can this be replaced by a deterministic script (bash, python, node)?
- **Complexity** — low / medium / high
- **Estimated tokens per invocation** — rough count of prompt + expected response tokens
- **Estimated time per invocation** — how long the LLM call typically takes (seconds)
- **Script alternative** — brief description of what the replacement script would do

## Output format

$ARGUMENTS

If the user provides a path as arguments, scan that path. Otherwise scan the current project root.

Present the audit as a structured report:

```
## Scriptify Audit Report

### Summary
- Files scanned: <N>
- LLM instructions found: <N>
- Scriptifiable items: <N>
- Estimated token savings per run: <N> tokens
- Estimated time savings per run: <N> seconds

### Items

| # | File | Type | Scriptifiable | Complexity | Tokens/run | LLM time/run | Time saved/run | Script alternative |
|---|------|------|---------------|------------|------------|--------------|----------------|--------------------|
| 1 | ...  | ...  | ...           | ...        | ...        | ...          | ...            | ...                |

### Recommendations
<Prioritised list of items to scriptify first, ordered by savings/complexity ratio>
```

After displaying the report, save a machine-readable JSON version to `.scriptify/audit-report.json` so that `/scriptify:generate` can consume it. Create the `.scriptify/` directory if it doesn't exist.

The JSON format should be:
```json
{
  "timestamp": "<ISO 8601>",
  "summary": { "files_scanned": 0, "instructions_found": 0, "scriptifiable": 0, "token_savings": 0, "time_savings_seconds": 0 },
  "items": [
    {
      "id": 1,
      "file": "<path>",
      "type": "<skill|command|prompt|claude_md|hook|mcp>",
      "scriptifiable": true,
      "complexity": "low",
      "tokens_per_run": 500,
      "time_per_run_seconds": 3,
      "description": "<what it does>",
      "script_alternative": "<what the script would do>"
    }
  ]
}
```

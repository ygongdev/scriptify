# scriptify

A Claude Code plugin that turns LLM instructions (skills, plugins, prompts) into standalone, deterministic scripts — more reliable than agent calls, with no token cost and faster execution.

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **audit** | `/scriptify:audit` | Scan a project for LLM instructions and report what can be scriptified, with token/time savings estimates |
| **generate** | `/scriptify:generate` | Generate standalone scripts from audit items or natural-language instructions |
| **verify** | `/scriptify:verify` | Verify generated scripts replicate the original LLM instruction behaviour |
## Usage

```bash
# Load the plugin during development
claude --plugin-dir /path/to/scriptify

# Audit current project
/scriptify:audit

# Generate scripts from audit results
/scriptify:generate item 1
/scriptify:generate items 1,3,5
/scriptify:generate all

# Generate from natural language
/scriptify:generate a script that lints markdown files

# Verify generated scripts
/scriptify:verify all
/scriptify:verify scripts/foo.sh

# Run self-test (deterministic checks)
./scripts/self_test.sh
```

## How it works

1. **Audit** scans for skill files, command files, CLAUDE.md instructions, hooks, and MCP configs. It estimates token cost and latency for each LLM instruction and identifies which ones can be replaced with deterministic scripts.

2. **Generate** reads the audit report (or takes direct instructions) and produces standalone bash/python/node scripts that replicate the LLM behaviour without any LLM API calls.

3. **Verify** validates generated scripts through static analysis (syntax, permissions, dependencies, safety) and behavioural comparison against the original instructions.

Generated scripts are stored in `scripts/`. Audit and verify reports are written to `$TMPDIR/scriptify/` and are not committed.

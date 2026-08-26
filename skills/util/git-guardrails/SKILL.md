---
name: git-guardrails
description: Set up a Claude Code PreToolUse hook that blocks dangerous git commands (push, reset --hard, clean -f, branch -D, checkout ., restore .) before they execute. Use when the user wants to prevent destructive or irreversible git operations, add git safety hooks, or stop an agent from pushing/force-resetting in Claude Code. This targets Claude Code's hook system specifically — if the user is on another agent runtime, say so rather than installing a hook that won't fire.
---

# git-guardrails

Install a PreToolUse hook that intercepts and blocks dangerous git commands before Claude executes them. The agent sees a message that it lacks authority for the command, and the operation never runs.

> Claude Code only. The hook relies on Claude Code's `PreToolUse` mechanism. On another runtime, this won't fire — tell the user instead of installing a dead hook.

## What gets blocked

- `git push` (all variants, including `--force`)
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

## Steps

### 1. Ask scope

Install for **this project only** (`.claude/settings.json`) or **all projects** (`~/.claude/settings.json`)? Don't assume — the blast radius differs.

### 2. Copy the hook script

The bundled script is [scripts/block-dangerous-git.sh](scripts/block-dangerous-git.sh). Copy it to the target based on scope, then `chmod +x`:

- **Project**: `.claude/hooks/block-dangerous-git.sh`
- **Global**: `~/.claude/hooks/block-dangerous-git.sh`

### 3. Add the hook to settings

Merge into the appropriate settings file's `hooks.PreToolUse` array — don't overwrite other settings.

**Project** (`.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous-git.sh" }
        ]
      }
    ]
  }
}
```

**Global** (`~/.claude/settings.json`): same shape, with `"command": "~/.claude/hooks/block-dangerous-git.sh"`.

### 4. Ask about customization

Ask whether to add or remove any patterns from the blocked list, and edit the copied script accordingly. The script depends on `jq` to parse the tool input. It is written to **fail closed** — if `jq` is missing, the hook blocks the command and tells the user to install jq, rather than silently waving every command through. Confirm `jq` is installed (`command -v jq`) so the hook does its real job instead of just refusing everything.

### 5. Verify

The completion criterion: a real blocked command actually exits non-zero. Run it and confirm:

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | <path-to-script>
```

Must exit `2` and print a `BLOCKED` message to stderr. A hook you didn't test is a hook you don't have.

Then confirm the **fail-closed** behaviour holds: with `jq` unavailable the script must still block (exit `2`), never pass through. Prove it by running with an empty `PATH` so `jq` can't be found:

```bash
echo '{"tool_input":{"command":"git status"}}' | PATH="$(mktemp -d)" /bin/bash <path-to-script>; echo "exit=$?"
```

A normally-safe command like `git status` should now exit `2` with the "requires 'jq'" message — that's the guardrail refusing to run blind rather than failing open.

## Owner / leadership lens

For a developer who is also CEO/CTO/CFO/PM, a guardrail is cheap insurance on irreversible loss:

- **The blocked operations are the irreversible ones.** A force-push or `reset --hard` can destroy work no review can recover. Spending five minutes to make the destructive path impossible is the same trade as a backup policy — you don't feel it until the day it saves you.
- **It shifts trust from vigilance to mechanism.** Instead of hoping you (or an agent) never run the wrong command while tired, the wrong command simply can't run. Mechanism beats discipline for high-cost, low-frequency mistakes.
- **Scope is a policy choice.** Global protects every repo by default; per-project lets a sandbox repo stay loose. Decide deliberately rather than defaulting.

## Attribution

Adapted from [mattpocock/skills `git-guardrails-claude-code`](https://github.com/mattpocock/skills/tree/main/skills/misc/git-guardrails-claude-code) (MIT). See THIRD_PARTY_NOTICES.md.

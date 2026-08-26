---
name: context-budget
description: >
  Audit how much of the context window is spent before the user even types —
  on agents, skills, MCP servers/tools, rules, and AGENTS.md/CLAUDE.md — then
  produce a ranked list of what to cut for the biggest token savings. Use when a
  session feels sluggish or output quality is slipping, after adding a bunch of
  skills/agents/MCP servers, when planning to add more and wondering if there's
  room, or when the user says "내 설정이 토큰 얼마나 먹는지 감사해줘",
  "MCP/스킬 정리하고 싶어", "설정이 무거워", "context bloat", "audit my setup",
  "how much does my config cost before I even type", "do I have room to add
  another MCP server". This audits the STANDING overhead of a CONFIG/SETUP
  present before you type anything — not the token cost of an ongoing
  conversation's messages, not the context you feed a subagent (that is
  iterative-retrieval), and not shortening the model's replies (that is
  terse-output).
---

# Context Budget

Every loaded agent, skill, MCP tool schema, and rule file spends context before the conversation starts. It accumulates quietly: a skill here, an MCP server there, until a chunk of the window is gone to things this session will never touch. This skill measures that standing overhead and tells you, in ranked order, what to cut.

## When this, not terse-output

`terse-output` shrinks what the model *says* back. **context-budget** shrinks what the setup *costs* before anyone says anything. One is about response length; this is about the fixed tax of your configuration. They compose but solve different problems.

## How it works

### Phase 1: Inventory
Scan each component source and estimate tokens (`words × 1.3` for prose, `chars / 4` for code-heavy files):

- **Agents / subagents** — tokens per definition. An agent's `description` loads into *every* task dispatch even if the agent is never used. Flag: definitions over ~200 lines, descriptions over ~30 words.
- **Skills** — tokens per `SKILL.md`. Note that only the description is always-loaded; the body loads on invocation. Flag: `SKILL.md` over ~400 lines. Skip identical mirrored copies to avoid double-counting.
- **MCP servers** — count servers and total tools. Estimate roughly ~500 tokens per tool schema. Flag: servers with over ~20 tools, and servers that merely wrap a CLI already available (`gh`, `git`, `npm`, and similar).
- **Rules / instructions** — tokens per rule or instruction file. Flag: overlap between files, content that duplicates AGENTS.md.
- **AGENTS.md / CLAUDE.md chain** — tokens across project + user-level files. Flag: combined over ~300 lines.

### Phase 2: Classify
Sort every component into a bucket:

| Bucket | Criteria | Action |
|--------|----------|--------|
| **Always needed** | referenced in AGENTS.md, backs an active command, or matches the current project | keep |
| **Sometimes needed** | domain-specific, not referenced, occasional | move to on-demand / lazy-load |
| **Rarely needed** | no reference, overlapping, no project match | remove |

### Phase 3: Detect issues
- **Bloated agent descriptions** — long `description` fields ride along in every task dispatch.
- **Heavy agents/skills** — oversized definitions inflate context on every spawn.
- **Redundant components** — a skill duplicating an agent, a rule duplicating AGENTS.md.
- **MCP over-subscription** — the single biggest lever. Many servers, or servers wrapping free CLI tools.
- **Instruction bloat** — verbose or stale AGENTS.md/CLAUDE.md sections.

### Phase 4: Report
```
Context Budget Report
Total standing overhead: ~XX,XXX tokens
Window: ~XXX,XXX  →  effective available: ~XX%

Component        Count   Tokens
Agents           N       ~X,XXX
Skills           N       ~X,XXX
Rules/AGENTS.md  N       ~X,XXX
MCP tools        N       ~XX,XXX

Issues (ranked by savings):
1. [action] → ~X,XXX tokens
2. [action] → ~X,XXX tokens
3. [action] → ~X,XXX tokens

Potential savings: ~XX,XXX (~XX% of overhead)
```
Verbose mode: add per-file token counts, the heaviest files line by line, the specific overlapping lines between redundant components, and a per-tool MCP schema-size list.

## Examples

**Audit** — "context 감사해줘" → scans setup, e.g. 16 agents (~12k), 28 skills (~6k), 87 MCP tools (~44k), AGENTS.md (~1k); flags 3 heavy agents and 14 MCP servers (3 CLI-replaceable); top saving: drop 3 MCP servers → about -27k tokens.

**Pre-expansion** — "MCP 5개 더 붙일 건데 여유 있어?" → current overhead ~33%; +5 servers (~50 tools) adds ~25k → pushes to ~45%; recommend dropping 2 CLI-replaceable servers first.

## Best practices
- **MCP is the biggest lever** — each tool schema is roughly ~500 tokens; a 30-tool server can outweigh all your skills combined.
- **Agent descriptions are always loaded** — even an agent you never invoke pays its description on every task dispatch.
- **Skill bodies are not** — a skill's `SKILL.md` body loads on invocation; only the description is standing cost. Judge skills by description length, agents by full size.
- **Estimate honestly** — `words × 1.3` for prose, `chars / 4` for code.
- **Audit after changes** — run after adding any agent, skill, or MCP server, to catch creep while it is one item, not thirty.

## Boundaries
This audits the fixed overhead of a *setup* (agents, skills, MCP, rules). It does not shorten the model's replies (that is `terse-output`) and does not measure the token cost of the running conversation's own messages. Reach for it when the question is "what is my configuration costing me before I even start", and act on it before adding more.

## Attribution

Adapted from [affaan-m/ecc](https://github.com/affaan-m/ecc) (MIT) — the four-phase audit (inventory → classify → detect → report), the token estimation heuristics (`words × 1.3`, `chars / 4`), the always-needed / sometimes / rarely buckets, the report shape and verbose mode, and the core insights ("MCP is the biggest lever", "agent descriptions load always") are preserved. Rewritten for this repo: the ECC-specific directory paths (`agents/*.md`, `rules/**`, `.mcp.json`) were generalized to agents/skills/MCP/rules in tool-agnostic terms including AGENTS.md, a boundary against `terse-output` was added, and Korean triggers were added. See THIRD_PARTY_NOTICES.md.

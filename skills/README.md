# Skills

> 한국어: [README.ko.md](./README.ko.md)

A collection of my own agent skills for daily use. Follows the open [Agent Skills](https://agentskills.io) standard and ships as the single `zizon` Claude Code plugin.

## Installation

```
/plugin marketplace add devjh-jiki/zizon
/plugin install zizon@zizon
```

## Buckets

| Bucket | Purpose |
|------|------|
| `token/` | Reduce token/context spend — terse output, lazy code, context budgeting |
| `design/` | Frontend design quality and taste |
| `planning/` | Turning a discussion into a spec, issues, or a domain model, and executing it |
| `review/` | Diff review through explicit lenses |
| `testing/` | Deciding what/how to test |
| `learning/` | Coaching-style learning from code or books |
| `util/` | Git safety and conflict resolution |

## Listed Skills

### Token

**Model-invoked** (the agent uses it automatically when it fits the task)

- [terse-output](./token/terse-output/SKILL.md) — Ultra-compressed communication mode; lite/full/ultra (adapted from JuliusBrussee/caveman)
- [context-budget](./token/context-budget/SKILL.md) — Audit standing context overhead across agents/skills/MCP/rules and rank what to cut (adapted from affaan-m/ecc)
- [lazy-code](./token/lazy-code/SKILL.md) — Force the laziest solution that works (YAGNI ladder, stdlib/native before deps); lite/full/ultra (adapted from DietrichGebert/ponytail)

**User-invoked** (run by a human only via `/command`)

- [i-have-adhd](./token/i-have-adhd/SKILL.md) — Reformat every response to lead with the next action, cap lists at 5, cut the fluff

### Design

**Model-invoked**

- [anti-slop-frontend](./design/anti-slop-frontend/SKILL.md) — Stop AI-built marketing/landing/portfolio frontends from looking templated (read the brief, three dials, avoid LLM defaults, pre-flight)

### Planning

**Model-invoked**

- [codebase-design](./planning/codebase-design/SKILL.md) — Vocabulary for designing deep modules
- [domain-modeling](./planning/domain-modeling/SKILL.md) — Actively build and sharpen the domain model (glossary + ADRs)

**User-invoked**

- [grill-me](./planning/grill-me/SKILL.md) — Relentless interview to stress-test a plan, design, decision, or business idea (inspired by mattpocock/skills)
- [to-prd](./planning/to-prd/SKILL.md) — Synthesize the current conversation into a PRD (no interview)
- [to-issues](./planning/to-issues/SKILL.md) — Break a plan/PRD into vertical-slice issues
- [implement](./planning/implement/SKILL.md) — Implement an agreed PRD/issues/slices into committed, tested code

### Review

**Model-invoked**

- [fe-review](./review/fe-review/SKILL.md) — Review a frontend diff through six lenses (requirement traceability, abstraction cost, state placement, interface predictability, async UX, hidden side effects)
- [be-review](./review/be-review/SKILL.md) — Review a Go backend diff for architecture boundaries, data integrity, error/security discipline, and Go idioms (requires a project canon adapter)

### Testing

**Model-invoked**

- [js-testing](./testing/js-testing/SKILL.md) — Decide what to test and at which level in a JS/TS codebase
- [webapp-testing](./testing/webapp-testing/SKILL.md) — Drive/test a local web app with Playwright (reconnaissance-then-action)

### Learning

**Model-invoked** (the agent uses it automatically in a learning context)

- [open-source-reverse-engineering-coach](./learning/open-source-reverse-engineering-coach/SKILL.md) — A coach for learning architecture, interfaces, and trade-offs by reverse-engineering open source
- [technical-book-coach](./learning/technical-book-coach/SKILL.md) — Learn technical books and docs through coaching (when English text is pasted, separates Korean translation + coaching)

### Util

**Model-invoked**

- [resolving-merge-conflicts](./util/resolving-merge-conflicts/SKILL.md) — Resolve a merge/rebase conflict by recovering each side's intent

**User-invoked / Claude Code hook**

- [git-guardrails](./util/git-guardrails/SKILL.md) — Set up a Claude Code PreToolUse hook that blocks dangerous git commands (Claude Code only)

## Upstream sync

Changes from trusted external repos such as [mattpocock/skills](https://github.com/mattpocock/skills) are
periodically detected by `.github/workflows/sync-upstream-skills.yml` and **proposed as PRs**.
Review the PRs and merge only the ones that meet your standards.

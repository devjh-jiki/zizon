# zizon

> 한국어: [README.md](./README.md)

A public meta-repo / index hub for everything I use as a developer.
The goal is to eliminate "where did I write that down again?".

> Private assets (side-project wiki, daily/travel notes, learning notes not for publishing)
> live in a separate private repo, `vault`. Only publishable things go here.

## Index

| Area | Path | Description |
|------|------|-------------|
| Skills | [`skills/`](./skills) | My own agent skills. 8 buckets, 22 skills. Installed as the Claude Code plugin `zizon`. |
| Bootstrap | [`bootstrap/`](./bootstrap) | Idempotent scripts that reproduce machine setup (marketplaces, plugins, MCP servers, hooks) from a declarative manifest. |
| Prompts | [`prompts/`](./prompts) | Frequently used prompt commands. |
| Learning / AI | [`learning/ai/`](./learning/ai) | AI learning roadmap + resources + log, from a frontend developer's view. |
| Snippets | [`snippets/`](./snippets) | Frequently used code/config snippets. |

## Install skills

Install from the Claude Code plugin marketplace.

```
/plugin marketplace add devjh-jiki/zizon
/plugin install zizon@zizon
```

### Recommended external plugins

[`cathrynlavery/diagram-design`](https://github.com/cathrynlavery/diagram-design) creates architecture, flowchart, sequence, data-model, and other technical diagrams as standalone HTML/SVG/PNG. It is not copied into this repository. Install the upstream plugin directly so its update and verification workflow remains intact.

```text
/plugin marketplace add cathrynlavery/diagram-design
/plugin install diagram-design@diagram-design
```

[`pbakaus/impeccable`](https://github.com/pbakaus/impeccable) is a design-quality tool with its own commands and detector rules that catch frontend output looking like AI-generated design slop. It is also not copied into this repository — install the upstream plugin directly so its update and verification workflow remains intact.

```text
/plugin marketplace add pbakaus/impeccable
/plugin install impeccable@impeccable
```

For taste judgment on marketing/landing/portfolio UI, reach for [`anti-slop-frontend`](./skills/design/anti-slop-frontend) first, then double-check with impeccable's detector rules when needed.

### Trust levels

Skills are labeled by verification stage:

- **Available** — personally tested and verified. Recommended for external install.
- **Review** — under evaluation; promoted to Available once verified.
- **Private** — personal-setup only; not in the marketplace.

| Skill | Bucket | Level | Description |
|-------|--------|-------|-------------|
| [terse-output](./skills/token/terse-output) | token | Available | Ultra-compressed output that cuts tokens while keeping accuracy; lite/full/ultra (adapted from JuliusBrussee/caveman). |
| [context-budget](./skills/token/context-budget) | token | Available | Audit standing context overhead across agents/skills/MCP/rules and rank what to cut. |
| [lazy-code](./skills/token/lazy-code) | token | Available | Force the laziest working solution via a YAGNI ladder; lite/full/ultra (adapted from DietrichGebert/ponytail). |
| [i-have-adhd](./skills/token/i-have-adhd) | token | Available | Lead every reply with the next action, cap lists at 5, cut the fluff. |
| [anti-slop-frontend](./skills/design/anti-slop-frontend) | design | Available | Stop AI-built frontends from looking templated: brief read, three dials, avoid LLM defaults, pre-flight (adapted from Leonxlnx/taste-skill). |
| [grill-me](./skills/planning/grill-me) | planning | Available | Relentless interview to stress-test a plan, decision, or business idea. |
| [to-prd](./skills/planning/to-prd) | planning | Available | Synthesize the current conversation into a PRD, no interview (adapted from mattpocock). |
| [to-issues](./skills/planning/to-issues) | planning | Available | Break a plan/PRD into vertical-slice issues (adapted from mattpocock). |
| [implement](./skills/planning/implement) | planning | Available | Implement an agreed PRD/issues/slices into committed, tested code (adapted from mattpocock). |
| [codebase-design](./skills/planning/codebase-design) | planning | Available | Vocabulary for designing deep modules (adapted from mattpocock). |
| [domain-modeling](./skills/planning/domain-modeling) | planning | Available | Build and sharpen a domain model, glossary, and ADRs (adapted from mattpocock). |
| [fe-review](./skills/review/fe-review) | review | Available | Review a frontend diff through six lenses (requirement traceability, abstraction cost, state placement, interface predictability, async UX, hidden side effects). |
| [be-review](./skills/review/be-review) | review | Available | Review a Go backend diff for architecture boundaries, data integrity, error/security discipline, and Go idioms (project-canon adapter contract). |
| [js-testing](./skills/testing/js-testing) | testing | Available | Decide what to test and at which level in a JS/TS codebase. |
| [webapp-testing](./skills/testing/webapp-testing) | testing | Available | Test a local web app with Playwright (adapted from anthropics). |
| [open-source-reverse-engineering-coach](./skills/learning/open-source-reverse-engineering-coach) | learning | Available | Learn an open-source project by interactive reverse-engineering. |
| [technical-book-coach](./skills/learning/technical-book-coach) | learning | Available | Coach-style learning from technical books/docs (KO translation + coaching). |
| [git-guardrails](./skills/util/git-guardrails) | util | Available | Block dangerous git commands via a hook (Claude Code only, adapted from mattpocock). |
| [resolving-merge-conflicts](./skills/util/resolving-merge-conflicts) | util | Available | Resolve merge/rebase conflicts by recovering intent (adapted from mattpocock). |

## Related repos (Organization)

| Repo | Public | Description |
|------|--------|-------------|
| [`zizon`](https://github.com/devjh-jiki/zizon) (this repo) | Public | Index hub |
| [`trending-newsletter`](https://github.com/devjh-jiki/trending-newsletter) | Public | GitHub trending KO newsletter (3 lenses: dev / founder / marketing) |
| [`ai-playground`](https://github.com/devjh-jiki/ai-playground) | Public | Practice projects from AI learning |
| `vault` | Private | Side-project wiki + daily/travel + learning notes |

## Documentation policy

All docs are managed as **English original + Korean `.ko.md` pair** (English is the source of truth).
Editing one side requires updating the other. CI checks for missing pairs. See [CLAUDE.md](./CLAUDE.md).

## License

[MIT](./LICENSE) · Third-party attributions: [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)

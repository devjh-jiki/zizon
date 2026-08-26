# AGENTS.md

This repository is a public index hub for reusable developer assets. Keep changes portable and preserve the existing English/Korean documentation pairs.

## Repository Map

- `skills/` — source of truth for runtime-neutral reusable agent skills, grouped into 7 buckets (`token`, `design`, `planning`, `review`, `testing`, `learning`, `util`) and shipped as the single `zizon` Claude Code plugin.
- `bootstrap/` — declarative manifest and idempotent scripts that reproduce machine setup (marketplaces, plugins, MCP servers, hooks).
- `scripts/` — validation and test scripts (`validate.mjs`, `*.test.mjs`, `bootstrap-helpers.test.sh`) run by `pnpm validate` / `pnpm test`.
- `.claude-plugin/` — Claude Code plugin (`plugin.json`) and marketplace (`marketplace.json`) metadata.
- `prompts/` — one-off copy-and-paste prompts. Promote repeated workflows to skills.
- `learning/ai/` — AI learning roadmap, references, and journal.
- `snippets/` — reusable code and configuration snippets.

## Skill Contract

Every skill lives at `skills/<bucket>/<skill-name>/SKILL.md`, where `<bucket>` is one of exactly seven allowed buckets: `token`, `design`, `planning`, `review`, `testing`, `learning`, `util`. Each uses YAML frontmatter:

```yaml
---
name: skill-name
description: What the skill does and when it should activate.
---
```

- Treat the English `SKILL.md` as the source of truth and keep `SKILL.ko.md` semantically synchronized.
- Use lowercase letters, numbers, and hyphens for `name`.
- Keep detailed procedures in the body and make `description` specific enough for reliable activation.
- `.claude-plugin/plugin.json` lists all skill paths explicitly (19 as of this writing). Adding, removing, or moving a skill means updating both the filesystem and this list — `pnpm validate` fails the build if they drift apart.
- Register public skills in the root README files.

## English/Korean Documentation Pairs

English is the source of truth except for the root README:

- `X.md` pairs with `X.ko.md`.
- When either file changes, update the other with the same meaning.
- Root documentation is the exception: `README.md` is Korean and pairs with `README.en.md`.
- Pairing is not required for `CLAUDE.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`, Changesets, code, executable command templates, templates, snippets, supporting files under `references/`, or files under `docs/superpowers/`.

Run the same checks as `.github/workflows/check-doc-pairs.yml` after documentation changes.

## Working Agreements

- Preserve unrelated user changes in the worktree.
- Inspect the relevant skill, its references, and indexes before editing.
- Prefer the narrowest complete change and avoid duplicating skill bodies.
- Do not add dependencies unless the task requires them.
- Use Changesets for release-worthy changes: `pnpm changeset`.

## Verification

After skill or manifest changes, run:

```sh
pnpm validate && pnpm test
```

For documentation changes, run the repository's pair-check logic or the corresponding GitHub Actions workflow.

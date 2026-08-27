# Third-Party Notices

This repository's skills draw on patterns and ideas from third-party work.
Attributions below. Where code or prose was adapted, the upstream license applies to that portion.

## Patterns referenced

- **[mattpocock/skills](https://github.com/mattpocock/skills)** (MIT) — overall skills repo structure
  (bucket folders, `.claude-plugin`, user-invoked vs model-invoked split) and the upstream-sync workflow
  approach are inspired by this repository. Specific skills such as `grill-me` informed our interview/
  decision-tree patterns. The following skills are **adapted** from mattpocock originals (core preserved,
  mattpocock-specific dependencies removed, an owner/leadership lens added):
  - `skills/planning/codebase-design` ← engineering/codebase-design
  - `skills/planning/to-prd` ← engineering/to-prd
  - `skills/planning/to-issues` ← engineering/to-issues
  - `skills/planning/domain-modeling` ← engineering/domain-modeling
  - `skills/planning/implement` ← engineering/implement
  - `skills/util/resolving-merge-conflicts` ← engineering/resolving-merge-conflicts
  - `skills/planning/grill-me` ← productivity/grill-me
  - `skills/util/git-guardrails` ← misc/git-guardrails-claude-code (includes the `block-dangerous-git.sh` script, copied verbatim)
  A full snapshot of the upstream repo is kept under `.upstream/mattpocock-skills/` for reference and
  attribution tracking (not installed or distributed).

- **[Anthropic Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)** —
  the `SKILL.md` format (YAML frontmatter `name` + `description`, progressive disclosure via `references/`)
  follows Anthropic's Agent Skills standard.

- **[anthropics/skills](https://github.com/anthropics/skills)** (Apache-2.0) — `skills/testing/webapp-testing`
  is **adapted** from the upstream `webapp-testing` skill (core reconnaissance-then-action Playwright workflow
  preserved; trimmed of the bundled `with_server.py` helper, with a runtime-portability note and an
  owner/leadership lens added).

- **[buYoung/skills](https://github.com/buYoung/skills)** (MIT) — the trust-level labeling approach
  (Available / Review / Private) is inspired by this repository.

- **[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)** (MIT) — `skills/token/lazy-code`
  is **adapted** from the `ponytail` skill: the YAGNI ladder, the lite/full/ultra intensity levels, and the
  "lazy, not negligent" framing are preserved. Renamed and rewritten for this repo (the code-comment marker
  `ponytail:` was changed to `lazy:`, Korean triggers were added, prose was condensed).

- **[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)** (MIT) — `skills/token/terse-output`
  is **adapted** from the `caveman` skill: the terse-communication rules, the intensity ladder, the auto-clarity
  carve-outs, and the "shrink the mouth, not the brain" idea are preserved. Rewritten for this repo — the caveman
  persona and the classical-Chinese (wenyan) levels were dropped in favor of plain terse prose in the user's own
  language (Korean-first).

- **[Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)** (MIT) — `skills/design/anti-slop-frontend`
  is **adapted** from the `design-taste-frontend` (taste-skill) skill: the brief-inference "design read", the three
  dials (DESIGN_VARIANCE / MOTION_INTENSITY / VISUAL_DENSITY), the official-system-vs-aesthetic split, the AI-tell
  catalogue, and the mechanical pre-flight check are preserved. Condensed into a shorter `SKILL.md` with the detailed
  rules moved into `references/`; renamed and generalized for this repo.

- **[affaan-m/ecc](https://github.com/affaan-m/ecc)** (MIT) — from ECC's large skill collection, one
  pure-prompt concept was extracted and rewritten for this repo (ECC's execution infrastructure — hooks, CLI,
  SQLite state, slash commands — is deliberately NOT vendored, so only the tool-agnostic methodology was taken):
  - `skills/token/context-budget` ← `context-budget` (four-phase setup token-overhead audit)
  This rewrite dropped ECC-internal skill references and infrastructure hooks, generalized ECC-specific paths to
  tool-agnostic terms, drew boundaries against this repo's neighbouring skills, and added Korean triggers.

A full snapshot of each upstream repo above is kept under `.upstream/<owner>-<repo>/` (fetched periodically by
`.github/workflows/sync-upstream-skills.yml`) for reference and attribution tracking — not installed or distributed.

## Vendored skills (per-skill attribution)

### skills/token/i-have-adhd

- Source: https://github.com/ayghri/i-have-adhd
- License: MIT
- Copyright: Copyright (c) 2026 Ayoub Ghriss
- Adapted: the ten output rules, the five reading facts, the "when to break the rules" exception list, and the
  pre-send check are preserved in substance from the upstream `skills/i-have-adhd/SKILL.md`. Frontmatter rewritten
  to this repo's `name` + `description` contract. User-invocation is preserved from upstream:
  `disable-model-invocation: true` stays set, so the skill only activates via `/i-have-adhd` (or an equivalent
  explicit ask), never automatically. The "Persistence" section and the reading-facts section (renamed "Why this
  shape") were also reordered relative to upstream, which leads with Persistence and puts the reading facts second.

### skills/testing/js-testing

- Source: https://github.com/goldbergyoni/javascript-testing-best-practices
- License: MIT
- Copyright: Copyright (c) 2019 Yoni Goldberg
- Adapted: not a transcription. Of the source's 50+ practices, only the subset where the right
  answer is genuinely contextual (and reasonable engineers disagree) is distilled into judgment
  calls: test-level selection, the three-part test name, black-box discipline, test data via
  factories instead of shared fixtures, snapshot pitfalls, and coverage pitfalls. Settled-consensus
  and tool-specific practices from the source are intentionally omitted. Frontmatter and prose are
  original to this repo; a Korean edition (`readme.kr.md`) was consulted to match terminology in
  `SKILL.ko.md`.

## Notes

- This file is English-only by policy (see CLAUDE.md "한/영 문서 페어 규칙" exemptions).
- When a skill adapts material from a specific upstream project, add an entry here with the source link
  and its license, and note the adaptation inside that skill's `SKILL.md`.

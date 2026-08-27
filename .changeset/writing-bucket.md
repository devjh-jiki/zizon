---
"@zizon/skills": minor
---

Add a `writing` bucket with three skills, bringing the plugin to 22 skills across 8 buckets.

- **`writing-domain-docs`** (new) — how to write a document whose job is to explain a business domain, a design judgment, or how a product works. Built from failures observed in this author's own documents, recorded in `baseline-failures.md`: template prompts shipped inside the document, repository docs restated as tables, headings whose bodies never deliver what the heading promised, concepts leaned on before they were grounded, numbers with no as-of date, and vagueness used to cover a gap in knowledge. The skill answers each with a positive recipe rather than a prohibition, and closes with a pre-save self-check. Non-interactive by design, so an unattended subagent can follow it.
- **`article-writing`** (promoted from `.upstream/affaan-m-ecc`) — long-form content that reads like a person with a point of view. Korean-cliché ban list added.
- **`living-docs-governance`** (promoted from `.upstream/affaan-m-ecc`) — assign four roles (constitution, map, status, history) to a project's existing docs, one canonical owner per fact, and keep a delete-zone so intentional removals are not recreated.

Both promoted skills were vendored under `.upstream/` but never declared in `plugin.json`, so they had never loaded.

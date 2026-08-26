---
name: to-issues
description: Break a plan, spec, or PRD into independently-grabbable work items using tracer-bullet vertical slices, output as Markdown and optionally published to whatever issue tracker the user has. Use when the user says "이슈로 쪼개줘", "작업 단위로 나눠줘", "break this into issues", "slice this PRD", "vertical slices 로 나눠줘", or wants a plan turned into shippable increments. Consumes the output of `to-prd`. Adapted from mattpocock/skills.
disable-model-invocation: true
---

# To Issues

Break a plan into independently-grabbable work items using vertical slices (tracer bullets).

This skill consumes a plan, spec, or PRD — typically the output of the `to-prd` skill — and slices it into increments. There is no required issue tracker: produce the breakdown as Markdown first, then offer to persist it wherever the user actually works.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a file path, an issue number, or a URL) as an argument, fetch and read it in full before slicing.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Item titles and descriptions should use the project's domain glossary vocabulary (see `CONTEXT.md` if it exists), and respect any ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the plan into **tracer bullet** items. Each item is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

<vertical-slice-rules>

- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Any prefactoring should be done first

</vertical-slice-rules>

A **prefactor** item is the one allowed exception to "demoable on its own" — it opens a seam without changing user behavior, so its acceptance is "existing behavior unchanged, tests still pass." Mark it clearly as a prefactor; don't dress it up as a feature slice.

If a stakeholder demands horizontal (by-layer) slices, push back with the rationale (nothing demoable until the end; integration risk surfaces last) and offer the compromise that still meets their real goal: **parallelize across slices, not layers.** A feature that lives behind a single seam often can't be sliced into independent parallel work — its slices form an incremental chain, each demoable on its own but building on the last. That's inherent to one-seam features, not a slicing failure; say so rather than forcing false independence.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories this addresses (if the source material has them)

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?

Iterate until the user approves the breakdown. If the user wants the breakdown in one shot (no back-and-forth), don't block — state your granularity and dependency assumptions, deliver the slices, and invite corrections.

### 5. Output and (optionally) publish

Render the approved slices as **Markdown** using the item template below, one block per slice, ordered by dependency (blockers first) so the "Blocked by" field can reference earlier slices.

Then offer to persist them — don't assume any particular tool:

- **GitHub** — create issues via `gh issue create` (apply whatever "ready" label the user uses, if any).
- **Linear** — create issues via the user's configured Linear integration/CLI.
- **Local files** — write one Markdown file per slice (e.g. under `docs/issues/`), or a single combined file.
- **Nothing** — just leave the Markdown in the conversation.

Only publish to a tracker if the user actually has one configured; ask which, rather than assuming. Publish in dependency order so you can reference real identifiers in "Blocked by". Do NOT close or modify any parent/source item.

<item-template>
## Parent

A reference to the parent/source item (the PRD, plan, or originating issue), if there is one. Otherwise omit this section.

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

Avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it here and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- A reference to the blocking slice (if any)

Or "None - can start immediately" if no blockers.

</item-template>

## Owner / leadership lens

For a developer who is also CEO/CTO/CFO/PM, the slicing IS the planning:

- **Vertical slices are shippable increments you can demo and validate early.** Each one is a chance to put something in front of a user (or yourself) and learn before the next is built. Horizontal slices give you nothing to show until the very end.
- **Dependency ordering is roadmap sequencing.** The "Blocked by" graph is your delivery plan in disguise — it tells you what unlocks what, and where the critical path runs.
- **The first slice should prove the riskiest assumption.** Order so the scariest unknown gets a tracer bullet first; you'd rather discover a dead end in week one than week six.

## Attribution

Adapted from [mattpocock/skills `to-issues`](https://github.com/mattpocock/skills/tree/main/skills/engineering/to-issues) (MIT). See THIRD_PARTY_NOTICES.md.

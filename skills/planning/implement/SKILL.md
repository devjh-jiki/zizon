---
name: implement
description: Implement a piece of work from a PRD, a set of issues, or vertical slices — the bridge from an agreed spec to committed code. Use when the user says "이거 구현해줘", "이슈대로 만들어줘", "implement this PRD/issue/slice", "build the spec", or has a written plan ready to execute. This is for executing an already-agreed spec — if the spec is vague or unwritten, use product-spec-builder / to-prd first; if the work is exploratory throwaway, use prototype.
disable-model-invocation: true
---

# implement

Turn an agreed spec — a PRD, a set of issues, or vertical slices — into committed, tested code. This is the last leg of the `product-spec-builder`/`to-prd` → `to-issues` → `prototype` → **implement** pipeline: the thinking is done; now build it without re-litigating it.

## Before you start

Confirm you actually have a spec to implement (an **input contract**). If the PRD/issues are vague or missing, don't invent them — say so and point the user at `product-spec-builder` or `to-prd`. If the idea is still exploratory, point at `prototype`. Only proceed when there's something concrete to execute against.

## Process

1. **Work test-first at the agreed seams.** Apply the `tdd` skill's discipline — one vertical slice at a time, red → green, tested through the public interface, inputs chosen to force each behavior into existence. "At pre-agreed seams" means: use the seam the spec/issues already named; don't invent new ones mid-implementation. If the spec named no seam, pick the highest clean one and note it.
2. **Keep the feedback loop tight as you go.** Run the project's type checker regularly *if it has one*, and run the single test file you're working on after each cycle. (Plain-JS or untyped repos have no typecheck step — skip it, don't fail on its absence.)
3. **Run the full suite once at the end** to catch cross-slice regressions.
4. **Self-review against the spec.** Done = every acceptance criterion has a passing test through the seam, and nothing outside the spec was added. Walk the criteria explicitly; a feature with no demoable/verifiable check isn't done.
5. **Commit to the current branch.** If the repo isn't a git repo or the user hasn't asked to commit yet, say what you *would* commit (files + message) instead of committing.

These steps lean on sibling skills (`tdd` for the loop, `to-prd`/`to-issues` for the input). If your environment wires them as slash-commands, use them; if not, the underlying capability — do TDD, review the work, commit — is what matters, not the command.

## Owner / leadership lens

For a developer who is also CEO/CTO/CFO/PM, implementation is where the spec's promises get cashed:

- **The spec is the contract; don't quietly renegotiate it while coding.** Scope creep invented at the keyboard is the most expensive kind — it ships untested, unreviewed, and unbudgeted. If reality contradicts the spec, stop and flag it, don't silently "improve" it.
- **A passing acceptance criterion is the unit of delivered value.** Track done against the criteria, not against lines written or hours spent. That's also what lets you hand the work off or walk away.
- **Tight loops are throughput.** The faster the red→green cycle, the more slices ship per session. A slow or missing test loop is the real bottleneck, not typing speed.

## Attribution

Adapted from [mattpocock/skills `implement`](https://github.com/mattpocock/skills/tree/main/skills/engineering/implement) (MIT). See THIRD_PARTY_NOTICES.md.

---
name: to-prd
description: Turn the CURRENT conversation into a PRD — no interview, just synthesis of what you've already discussed. Use when the user says "PRD 만들어줘", "이 대화 PRD 로", "to PRD", "make a PRD from this", "기획서로 정리해줘", after a design discussion that's ready to be written up. Adapted from mattpocock/skills.
disable-model-invocation: true
---

# to-prd

This skill takes the current conversation context and codebase understanding and produces a PRD. Do NOT interview the user — just synthesize what you already know.

**Relationship to `product-spec-builder`:** `to-prd` assumes the thinking is already done in this conversation and only *writes it up* — no questions. `product-spec-builder` is the opposite: it *interviews first* to fill gaps before drafting. If you find yourself with big unknowns, you want `product-spec-builder`, not this skill.

Litmus for "big unknown vs gap": if you'd have to *invent* the Problem Statement, the primary user, or the success criterion, that's a big unknown — stop and redirect to `product-spec-builder`. If the frame is settled and only details are open (a default value, exact copy, a secondary edge case), that's a gap — note it under Further Notes as an open question and synthesize anyway. The redirect is itself a checkpoint: tell the user why, and offer to proceed if they actually have the answers and just didn't write them down.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. If the project has a context doc (e.g. `CONTEXT.md`) or recorded architecture decisions, use that domain vocabulary throughout the PRD and respect decisions in the area you're touching.

2. Sketch out the seams at which you're going to test the feature. Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better — the ideal number is one.

   Check with the user that these seams match their expectations. If the user clearly wants the PRD in one shot, don't block — state your seam choice as an assumption in Implementation Decisions and let them correct it.

3. Write the PRD using the template below as **Markdown**. Then **offer to persist it** — don't assume any particular tool:
   - Ask whether to save it as a file (and where), and/or
   - Publish it to an issue tracker **only if the user has one configured** (ask which, and apply whatever "ready" label they use).

   If the user doesn't want it saved anywhere, just output the Markdown.

<prd-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.

</prd-template>

## Owner / leadership lens

For a developer who is also CEO/CTO/CFO/PM, a PRD is the contract between "what we want" and "what we'll build":

- **The Problem Statement is your strategy in one paragraph.** If you can't state the user's problem crisply, you're not ready to spend engineering money on it. Write that line first; everything downstream is implementation.
- **Out of Scope is where you protect the budget.** Every line here is a "no" that buys focus. As the person paying for the work, be explicit about what v1 deliberately doesn't do.
- **User Stories are your acceptance and your roadmap.** They double as the demo script and the slice list. If a story can't be demoed, it isn't done.

## Attribution

Adapted from [mattpocock/skills `to-prd`](https://github.com/mattpocock/skills/tree/main/skills/engineering/to-prd) (MIT). See THIRD_PARTY_NOTICES.md.

---
name: domain-modeling
description: Build and sharpen a project's domain model — its ubiquitous language and the architectural decisions behind it. Use when the user wants to pin down domain terminology, define a glossary, record an architectural decision (ADR), resolve ambiguous terms, or when another skill needs to maintain the domain model. Triggers include "도메인 모델링", "용어 정리해줘", "용어집 만들자", "이 결정 ADR 로 남겨줘", "ubiquitous language", "이 단어 뜻이 뭐야". Adapted from mattpocock/skills.
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the *active* discipline — challenging terms, inventing edge-case scenarios, and writing the glossary and decisions down the moment they crystallise. (Merely *reading* `CONTEXT.md` for vocabulary is not this skill — that's a one-line habit any skill can do. This skill is for when you're changing the model, not just consuming it.)

## File structure

Most repos have a single context:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If a `CONTEXT-MAP.md` exists at the root, the repo has multiple contexts. The map points to where each one lives:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← context-specific decisions
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

Create files lazily — only when you have something to write. If no `CONTEXT.md` exists yet, create one when the first term is resolved. If no `docs/adr/` exists yet, create it when the first ADR is needed. Don't scaffold empty files up front.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Don't batch these up — capture them as they happen. Use the format in [references/CONTEXT-FORMAT.md](references/CONTEXT-FORMAT.md).

`CONTEXT.md`'s `## Language` section is a glossary and nothing else — totally devoid of implementation details. Do not treat the glossary as a spec, a scratch pad, or a repository for implementation decisions. (Settled-but-reversible choices may live in a separate `## Decisions` list below the glossary — see references/CONTEXT-FORMAT.md — but never mix them into term definitions.)

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. Use the format in [references/ADR-FORMAT.md](references/ADR-FORMAT.md).

A decision that is surprising and a real trade-off but *easy to reverse* (tunable policy, a default, a convention) is not an ADR — but don't lose it. Record it in a `## Decisions` list in `CONTEXT.md`, separate from the glossary. Promote it to an ADR only if it later proves hard to reverse.

## Owner / leadership lens

For a developer who is also CEO/CTO/CFO/PM, a shared domain language is a communication asset, not bureaucracy:

- **A glossary is alignment capital.** When the team, investors, and your own docs all use the same word for the same thing, every conversation gets cheaper. Ambiguous terms ("account", "user", "subscription") cost real money — in mis-built features, mis-scoped contracts, and onboarding time spent re-explaining.
- **ADRs are institutional memory.** The reason behind an irreversible decision is worth more than the decision itself. Six months later, a recorded "why" stops you (or a new hire, or an agent) from re-litigating a settled trade-off or "fixing" something that was deliberate.
- **The language is the product boundary.** Where you draw the line between Customer and User, or Order and Invoice, is a business decision before it's a schema. Get the words right and the contracts, pricing, and reporting fall out of them.

## Attribution

Adapted from [mattpocock/skills `domain-modeling`](https://github.com/mattpocock/skills/tree/main/skills/engineering/domain-modeling) (MIT). See THIRD_PARTY_NOTICES.md.

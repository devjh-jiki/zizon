---
name: codebase-design
description: Shared vocabulary for designing deep modules. Use when the user wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, judge whether a module is too shallow or over-abstracted, make code more testable or AI-navigable, or says "모듈 설계", "인터페이스 설계", "너무 얕은/깊은", "테스트하기 쉽게", "아키텍처 설계", or when another skill needs the deep-module vocabulary. This is for designing a module's shape and interface — for a large multi-module restructure of an existing codebase, hand off to improve-codebase-architecture (which uses this vocabulary). Adapted from mattpocock/skills.
---

# Codebase Design

Design **deep modules**: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface. Use this language and these principles wherever code is being designed or restructured. The aim is leverage for callers, locality for maintainers, and testability for everyone.

This skill works at the scale of *one module's shape and interface*. It runs two ways: on its own when someone is designing or judging a single module, and as the shared vocabulary another skill reaches for (e.g. `improve-codebase-architecture` uses these terms while restructuring). Two boundaries keep it in its lane: if there's no concrete module in view yet — just a vague "improve the architecture" — pin down which module or seam is in question before applying the vocabulary, rather than inventing one. And if the real task is a multi-module restructure of an existing codebase (mapping deepening opportunities across many seams, sequencing the work), hand off to `improve-codebase-architecture`, which drives that at the right scale using this same language.

## Glossary

Use these terms exactly — don't substitute "component," "service," "API," or "boundary." Consistent language is the whole point.

**Module** — anything with an interface and an implementation. Deliberately scale-agnostic: a function, class, package, or tier-spanning slice. _Avoid_: unit, component, service.

**Interface** — everything a caller must know to use the module correctly: the type signature, but also invariants, ordering constraints, error modes, required configuration, and performance characteristics. _Avoid_: API, signature (too narrow — they refer only to the type-level surface).

**Implementation** — what's inside a module, its body of code. Distinct from **Adapter**: a thing can be a small adapter with a large implementation (a Postgres repo) or a large adapter with a small implementation (an in-memory fake). Reach for "adapter" when the seam is the topic; "implementation" otherwise.

**Depth** — leverage at the interface: the amount of behaviour a caller (or test) can exercise per unit of interface they have to learn. A module is **deep** when a large amount of behaviour sits behind a small interface, **shallow** when the interface is nearly as complex as the implementation.

**Seam** _(Michael Feathers)_ — a place where you can alter behaviour without editing in that place; the *location* at which a module's interface lives. Where to put the seam is its own design decision, distinct from what goes behind it. _Avoid_: boundary (overloaded with DDD's bounded context).

**Adapter** — a concrete thing that satisfies an interface at a seam. Describes *role* (what slot it fills), not substance (what's inside).

**Leverage** — what callers get from depth: more capability per unit of interface they learn. One implementation pays back across N call sites and M tests.

**Locality** — what maintainers get from depth: change, bugs, knowledge, and verification concentrate in one place rather than spreading across callers. Fix once, fixed everywhere.

## Deep vs shallow

**Deep module** = small interface + lots of implementation:

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
└─────────────────────┘
```

**Shallow module** = large interface + little implementation (avoid):

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

When designing an interface, ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

## Principles

- **Depth is a property of the interface, not the implementation.** A deep module can be internally composed of small, mockable, swappable parts — they just aren't part of the interface. A module can have **internal seams** (private to its implementation, used by its own tests) as well as the **external seam** at its interface.
- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through. If complexity reappears across N callers, it was earning its keep. Apply it to the *interface* and the *implementation* separately: a one-member `RetryPolicy` interface can fail the test (delete it) while the backoff *logic* behind it passes (keep it). And when deletion's outcome depends on whether the module holds real policy (a dispatcher that might just forward, or might own fan-out/rate-limiting), inspect that behaviour before judging — the count of callers alone won't tell you.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test *past* the interface, the module is probably the wrong shape.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Don't introduce a seam unless something actually varies across it. Count *axes of variation*, not *number of implementations*: N implementations of one interface (three notification channels behind one `Channel`) still justify exactly one seam, not N.
- **Depth can leak.** Depth is leverage at the interface — but an interface that inverts control (a streaming module that takes a caller-supplied callback/handler) can be deep in behaviour while *exporting* complexity to the caller (callback ordering, reentrancy). Count that exported complexity against the interface; a small type signature isn't automatically a small interface.

## Designing for testability

Good interfaces make testing natural:

1. **Accept dependencies, don't create them.**

   ```typescript
   // Testable
   function processOrder(order, paymentGateway) {}

   // Hard to test
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **Return results, don't produce side effects.**

   ```typescript
   // Testable
   function calculateDiscount(cart): Discount {}

   // Hard to test
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. **Small surface area.** Fewer methods = fewer tests needed. Fewer params = simpler test setup.

## Relationships

- A **Module** has exactly one **Interface** (the surface it presents to callers and tests).
- **Depth** is a property of a **Module**, measured against its **Interface**.
- A **Seam** is where a **Module**'s **Interface** lives.
- An **Adapter** sits at a **Seam** and satisfies the **Interface**.
- **Depth** produces **Leverage** for callers and **Locality** for maintainers.

## Rejected framings

- **Depth as ratio of implementation-lines to interface-lines** (Ousterhout): rewards padding the implementation. We use depth-as-leverage instead.
- **"Interface" as the TypeScript `interface` keyword or a class's public methods**: too narrow — interface here includes every fact a caller must know.
- **"Boundary"**: overloaded with DDD's bounded context. Say **seam** or **interface**.

## Going deeper (optional)

Two deeper moves, summarized inline so you don't need separate reference files:

- **Deepening a cluster given its dependencies** — categorize a module's dependencies, keep seam discipline (test through the interface, don't reach past it), and prefer *replacing* an adapter over *layering* another shallow wrapper on top. If a project context doc (e.g. `CONTEXT.md`) exists, name modules after the concepts it defines.
- **Design it twice** — before committing to an interface, sketch it several radically different ways (you can spin up parallel sub-agents to do this), then compare the candidates on depth, locality, and seam placement. The winner is rarely the first sketch. Two clarifications: candidates only count as "radically different" if the **seam is in a different place** (different interface, different thing crossing it) — not cosmetic variants; aim for ~3. And divergent sketching will *tempt* you to invent seams — so apply the one-vs-two-adapters and deletion tests **as a filter after** sketching, not during. Diverge first, then prune.

## Owner / leadership lens

For a developer who is also CEO/CTO/CFO/PM, module design is a capital-allocation decision:

- **Depth is leverage, and leverage compounds.** A deep module pays back across every caller and every future feature — the same way a good hire or a reusable process does. Spend design effort where the payback is highest.
- **Locality lowers your bus factor and your onboarding cost.** When change concentrates in one place, a new teammate (or future-you, or an agent) can be productive without holding the whole system in their head. That is a real org cost you control with interface design.
- **Seams are optionality.** A clean seam lets you swap a vendor, change a pricing engine, or replace a slow path later without a rewrite — the engineering equivalent of not locking yourself into a single supplier. But options have a premium: a speculative seam (one adapter, no second on the roadmap) is paid for *every day* in extra indirection, lower locality, and onboarding cost, while "extract the interface later" is a cheap, near-mechanical refactor done with full information once the second adapter actually exists. Buy the option when the second adapter is in hand, not six months early on spec.

## Attribution

Adapted from [mattpocock/skills `codebase-design`](https://github.com/mattpocock/skills/tree/main/skills/engineering/codebase-design) (MIT). See THIRD_PARTY_NOTICES.md.

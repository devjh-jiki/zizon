# CONTEXT.md Format

## Structure

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
{A one or two sentence description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others under `_Avoid_`.
- **Conditional avoids are fine.** When a word is correct for one term but wrong for another (e.g. "cancel" means ending a Subscription, not voiding an Order), qualify it: `_Avoid_: cancel (when meaning an Order)`. A flat synonym list can't express overloads; the qualifier can.
- **Keep definitions tight.** One or two sentences max. Define what it IS, not what it does.
- **Roles and events are valid entries**, not just entities. A role ("Owner — the User responsible for an Account's billing; a reassignable role") or a domain event ("PaymentFailed — a domain event signalling a charge against an Account did not succeed") belongs here when the *name and meaning* are project-specific. The event's delivery mechanism does not — that's an ADR or a Decisions-list entry.
- **Only include terms specific to this project's context.** General programming concepts (timeouts, error types, utility patterns) don't belong even if the project uses them extensively. Before adding a term, ask: is this a concept unique to this context, or a general programming concept? Only the former belongs.
- **Group terms under subheadings** when natural clusters emerge. If all terms belong to a single cohesive area, a flat list is fine.

## Optional `## Decisions` section

A `CONTEXT.md` may carry a short `## Decisions` list *below* the `## Language` glossary for settled-but-reversible choices that don't merit an ADR (tunable policy, defaults, conventions). One line each: the choice plus a few words of why. Keep it visually separate from the glossary — `## Language` defines terms only; `## Decisions` records choices. Anything hard to reverse graduates to an ADR instead (see ADR-FORMAT.md).

```md
## Decisions

- Email retry budget is longer than push (email is less time-sensitive).
- Dead-letter entries retain for 30 days, manual replay only (auto-replaying a stale OTP is harmful).
```

## Single vs multi-context repos

**Single context (most repos):** One `CONTEXT.md` at the repo root.

**Multiple contexts:** A `CONTEXT-MAP.md` at the repo root lists the contexts, where they live, and how they relate to each other:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) — generates invoices and processes payments
- [Fulfillment](./src/fulfillment/CONTEXT.md) — manages warehouse picking and shipping

## Relationships

- **Ordering → Fulfillment**: Ordering emits `OrderPlaced` events; Fulfillment consumes them to start picking
- **Fulfillment → Billing**: Fulfillment emits `ShipmentDispatched` events; Billing consumes them to generate invoices
- **Ordering ↔ Billing**: Shared types for `CustomerId` and `Money`
```

The skill infers which structure applies:

- If `CONTEXT-MAP.md` exists, read it to find contexts
- If only a root `CONTEXT.md` exists, single context
- If neither exists, create a root `CONTEXT.md` lazily when the first term is resolved

When multiple contexts exist, infer which one the current topic relates to. If unclear, ask.

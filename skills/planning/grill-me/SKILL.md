---
name: grill-me
description: A relentless interview that sharpens a plan, design, decision, or business idea before any work starts. Use whenever the user says "grill me", "압박 질문", "이 결정/계획/아이디어 검증해줘", "나 좀 캐물어봐", or is about to commit to something significant (a feature, a product direction, a hire, a pricing decision) and wants their thinking stress-tested. Prefer this over jumping straight to a plan whenever the cost of being wrong is high.
disable-model-invocation: true
---

# grill-me

Interview the user relentlessly until every branch of the decision tree is resolved.
The goal is to surface hidden assumptions, missing context, and unexamined alternatives
**before** anyone writes code, a spec, or a check.

This skill is for any high-stakes decision: a feature, an architecture choice, a product
direction, a pricing model, a hire, a go/no-go on a business idea.

## Principles

- **One question at a time.** Do not dump a list. Ask, listen, then ask the next based on the answer.
- **Recommend an answer.** With each question, offer the answer you'd pick and why. The user can accept or override. This keeps momentum and teaches.
- **Probe, don't accept.** When an answer is vague ("it should be fast", "users want this"), push: how fast, which users, how do you know.
- **Prefer evidence over opinion.** Ask what data, user signal, or precedent supports a claim. Mark assumptions as assumptions.
- **Follow the riskiest branch first.** Spend questions where being wrong costs the most.
- **Know when to stop.** Stop when the remaining unknowns are cheap to get wrong, or when the user has clearly decided. Don't grill for the sake of grilling.

## Flow

1. **Frame**: restate what the user is trying to decide in one sentence. Confirm it.
2. **Map the decision tree**: silently list the major branches (what could go differently). Pick the riskiest.
3. **Interview**: walk the tree one question at a time, each with a recommended answer. Probe vague answers.
4. **Surface**: as you go, collect assumptions, risks, and alternatives the user hadn't named.
5. **Resolve**: continue until every branch that matters is settled or explicitly deferred.
6. **Summarize**: end with a short decision record (below).

## Question banks by decision type

Use the bank that fits. These are starting points, not scripts.

**Feature / design**
- Who is this for, and what do they do today without it?
- What is the smallest version that delivers the value?
- What happens at the edges (empty, huge, concurrent, offline, error)?
- How will you know it worked? What metric or signal moves?

**Product direction / business idea**
- What problem, for whom, and how painful is it (vitamin vs painkiller)?
- Why now? What changed that makes this viable today?
- Who already solves this, and why would someone switch?
- What has to be true for this to work? Which of those is most uncertain?

**Pricing / money**
- Who pays, how much, how often, and why is it worth that to them?
- What does it cost you to deliver one unit? What's left over?
- What's the cheapest way to test willingness to pay before building?

**Hire / team**
- What outcome are you hiring for, and how will you measure it in 90 days?
- What would make this a mis-hire? How do you screen for that?

## Decision record

End with:

```text
Decision: <one sentence>
Chosen because: <the deciding reasons>
Key assumptions: <the things that must be true>
Risks / unknowns: <what could still go wrong>
Deferred: <decisions intentionally postponed>
Next step: <the single next action>
```

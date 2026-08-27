---
name: js-testing
description: Use when deciding what to test and at which level in a JS/TS codebase — test level selection, naming, data setup, and what not to assert. For driving a browser use webapp-testing; for the red-green-refactor loop use superpowers:test-driven-development.
---

# js-testing

Judgment calls for *what* to test and *at which level*, made before a single test exists. This is not about running tests or writing the implementation.

**Scope boundary — three skills, three moments:**

- **`js-testing`** (this skill) — the judgment call, before any test exists: what level, what name, what data, what not to assert.
- **`webapp-testing`** — driving a real browser against a running app (Playwright: click flows, screenshots, console/network logs). Reach for it once you know you need browser-level execution.
- **`superpowers:test-driven-development`** — the red-green-refactor loop while implementing. Reach for it once you've decided what a test should check and are about to write it.

If the question is "should this be a unit test or an integration test," that's here. If the question is "how do I get Playwright to click this button," that's `webapp-testing`. If the question is "I'm implementing a function, what test do I write first," that's TDD.

## Distillation, not transcription

Source: [goldbergyoni/javascript-testing-best-practices](https://github.com/goldbergyoni/javascript-testing-best-practices) (MIT), 50+ practices across test anatomy, backend, frontend, coverage, and CI. Most of those practices are settled consensus or tool-specific mechanics (AAA structure, don't `sleep()` in E2E, don't catch errors — expect them, use realistic fake data, tag tests by speed) — a competent developer doesn't hesitate on them, and repeating them here would cost context for zero decision value. What follows is only the subset where the right answer is genuinely contextual and reasonable engineers land in different places. For everything else, read the source.

## 1. Test-level selection

**Principle:** match the test level to where the risk actually lives, not to a fixed pyramid ratio of unit/integration/e2e.

**Why it splits:** the testing pyramid assumes logic-heavy code where isolating a unit is cheap and meaningful. An integration-centric service (thin business logic, mostly wiring a DB/queue/API together) gets more real coverage per test-minute from a component/integration test than from ten unit tests that mock away everything that actually matters. Where "thin" starts is a judgment call, not a rule.

**Criterion:** ask, "if this function's internals were swapped for a different but correct implementation, would the test still need to change?" If most of the code is glue with no branching logic to isolate, test it at the level that includes the glue (component/integration). If there's a piece with real decision logic (branches, edge cases, calculations), unit-test that piece directly and let the surrounding glue live in a higher-level test.

## 2. The three-part test name

**Principle:** a test name should answer three questions in one read — what's under test, under what scenario, and what's expected — so a failure is diagnosable from the test report alone, without opening the code.

**Why it splits:** this reads as boilerplate for trivial tests, and teams disagree on whether the third part needs an explicit "should." The disagreement isn't about the idea, it's about where the cost of verbosity stops being worth it.

**Criterion:** if someone unfamiliar with the code — a future you, a teammate reading a failed CI run — needs to understand what broke from the test name alone, write all three parts (`describe(unit) > describe(scenario) > it(expectation)`). If the test is one of a handful in a file only its author ever reads, the full ceremony isn't buying anything.

## 3. Black-box discipline

**Principle:** assert on public behavior and output; a test should never break because an internal was renamed or refactored while the observable result stayed correct.

**Why it splits:** it's tempting to unit-test an internal helper directly — it's already isolated, mocking is less work, and the assertion is simpler to write. The temptation is strongest exactly where it's most wrong: on code most likely to be refactored soon.

**Criterion:** does the internal thing have its own contract — is it consumed, deployed, or reasoned about separately from the function that calls it (a shared utility, a module boundary)? If yes, it's effectively public; test it directly. If it exists purely as an implementation detail that could be inlined tomorrow without anyone noticing, don't assert on it directly — exercise it only through the public entry point.

## 4. Test data: factories, not shared fixtures

**Principle:** each test builds and owns the data it needs (a factory function or builder called inside the test) rather than depending on data seeded once for the whole suite.

**Why it splits:** seeded/shared fixtures are genuinely faster to set up and run, and for read-only tests (pure queries) reusing seeded data is a legitimate, deliberate performance trade. The disagreement is about where "faster" stops being worth the coupling.

**Criterion:** does the test mutate the data it reads (update, delete, insert into a record other tests also touch)? If yes, always give it its own factory-created data — mutation plus shared state is exactly what produces a failure whose root cause is a different, unrelated test. If the test only reads and never mutates, seeded shared data is an acceptable trade — but make that choice deliberately, not by default.

## 5. Snapshot pitfalls

**Principle:** use snapshots only when they're short and inline (a few lines a reviewer will actually read before approving an update) — not large external files nobody inspects.

**Why it splits:** a big auto-generated snapshot looks like free coverage, and it genuinely will catch some regressions. The question is whether "diff changed, click accept" is testing anything, or just adding review-fatigue theater that goes rubber-stamped.

**Criterion:** on a PR that changes the snapshot, would a reviewer actually read the diff before approving it, or skim past a wall of JSON/DOM? If they'd read it, the snapshot is doing its job — keep it short enough that this stays true. If it's long enough that approval is reflexive, replace it with an assertion on the specific fields/shape that matter (or a schema check), not the whole document.

## 6. Coverage pitfalls

**Principle:** coverage percentage measures which lines were *visited* by a test run, not which behaviors were *verified* — it can sit at 100% while zero assertions check anything meaningful.

**Why it splits:** teams disagree over whether a coverage gate is worth enforcing at all. Skeptics are right that a number alone proves nothing; gate proponents are right that a threshold at least stops a PR from landing with zero tests. Both are correct about different failure modes.

**Criterion:** use coverage as a floor (catch code that has literally no test touching it), never as a ceiling or a quality proxy. To check whether tests verify anything beyond visiting the line, ask by eye: "if I flipped this comparison operator or return value, would any test actually fail?" — that question is what mutation testing automates; you don't need the tool to apply the judgment.

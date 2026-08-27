---
name: be-review
description: Use when reviewing Go backend code changes (API services, workers, data layers) for architecture boundaries, data integrity, error/security discipline, and Go idioms - e.g. "review this Go diff", "backend review", "Go 코드 리뷰해줘", "백엔드 diff 봐줘". Runs as the judgment tier above machine gates. Requires a project adapter that injects the project's canonical checklist; without one, review with generic lenses only and say so explicitly. NOT for style/formatting nits (gofmt and golangci-lint own those), NOT for non-Go code, NOT a replacement for CI gates such as architecture linters or API-breaking checks.
---

# Go Backend Review

Review Go backend diffs at the level machines cannot judge: boundary intent, data integrity, failure-mode discipline, and idiomatic design. Every finding must carry a reason a reader can verify (a project-canon clause or a public Go norm), never taste alone.

## Two-tier model

1. **Machine gates run first.** gofmt, golangci-lint, an architecture linter (e.g. go-arch-lint), and API-breaking checks are CI's job. If the diff has violations those tools would catch, note it in one line and move on. Do not enumerate them.
2. **This skill reviews judgment calls**: the four lenses below.

## Lens 1: Architecture and boundaries

- Does the domain layer import frameworks, HTTP, or DB drivers? (It must not.)
- Does one module write another module's tables directly instead of going through an application port?
- Do handlers contain logic beyond use-case invocation and error mapping?
- Are domain entities serialized directly as API responses instead of DTOs?
- Is speculative abstraction or premature network indirection introduced "for future split"? (YAGNI.)

## Lens 2: Data integrity and determinism

- Do computation functions read the current time or call external APIs internally instead of receiving them as inputs? (Determinism: same input snapshot, same rule version, same result.)
- Is money represented as integers in the smallest unit? Are rates basis points or explicit decimals, never floats?
- Are versioned rules, input snapshots, and calculator versions persisted with results where the project requires reproducibility?
- Are background job handlers idempotent? Do job payloads carry raw personal data? (They must not.)

## Lens 3: Errors, security, privacy

- Do error responses follow the project's error model (e.g. RFC 9457 Problem Details) without leaking internal messages, SQL, or personal data?
- Are logs structured with the project's correlation keys (trace/request/job IDs, hashed user IDs)?
- Does outbound fetching enforce a registered domain allowlist? (SSRF.)
- Are auth token claims (issuer, audience, expiry, key ID) actually verified rather than trusted from a header?

## Lens 4: Go idioms

Grounded in the Google Go Style Guide, Go Code Review Comments, and the Uber Go Style Guide:

- Error wrapping (`%w`) and context propagation; `panic` only for unrecoverable startup failure.
- Interfaces defined small, on the consumer side; no producer-side god interfaces.
- Goroutine lifetime and channel ownership are explicit; no leaks.
- Table-driven tests; integration tests use real dependencies (e.g. testcontainers) where the project prescribes them.
- No `SELECT *`; queries carry names and cardinality when the project uses a query generator.

## Output format

Sort findings by severity: `file:line / P0 (breaks correctness or leaks data) | P1 (violates project canon) | P2 (advisory) / problem / reason (canon clause or norm) / suggestion`. Phrase uncertain findings as questions. End with a checklist pass over the project's definition of done, marking only items the diff touches.

## Project adapter contract

This skill is a **core**. Each project must supply an adapter (for example, a project-scoped agent file) that injects:

1. The project's definition-of-done checklist for backend changes.
2. Canonical domain enums, versioning formats, forbidden patterns, and any required response/log formats the generic lenses only describe in the abstract (e.g. the exact error envelope, the exact correlation-key set).
3. The review's default target scope: which diff, directory, and stack to review.
4. Where review output is written, and whether it may be committed.

If no adapter context is present, say "generic lenses only, no project canon injected" at the top of the review and proceed with lenses 1-4. Reference implementation: the jjan monorepo's `be-reviewer` agent, which injects its own `docs/` (decision records and backend completion criteria) plus a default review scope of `services/backend`.

## What not to do

- No style or formatting nits.
- No re-listing of machine-gate violations.
- No wholesale redesign demands for code outside the diff.
- No taste-only objections without a citable reason.

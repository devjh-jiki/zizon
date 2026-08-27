---
name: fe-review
description: Use when reviewing frontend changes (React/Next.js components, hooks, state, async UI) — reviews a diff through six explicit lenses (requirement traceability, abstraction cost, state placement, interface predictability, async UX, hidden side effects) and writes the result to docs/reviews/.
---

# Frontend Review

Review frontend diffs through six explicit lenses instead of a checklist of style rules or an imitation of any specific reviewer. Every finding must point at something a reader can verify in the diff — a missing case, a mismatch, an undocumented rule — never taste alone.

## Input

Default review target is `git diff main...HEAD`. The caller may instead specify:

- a file list
- a commit range (`git diff A..B`)
- a PR (fetch the diff for that PR)

If none of these resolve to a non-empty diff, say so and stop — do not review the whole tree as a substitute.

## Apply the six lenses, in order

For each lens: ask its question, walk its checklist against the diff, and only raise a finding when something in the checklist actually fails. A lens that finds nothing gets a one-line "해당 없음" pass, not a stretched objection.

1. **요구사항 추적성** — does this code read as satisfying some stated requirement?
2. **추상화 비용** — does this abstraction earn back more than it costs?
3. **상태의 위치** — does state promoted to global/context actually need to live there?
4. **인터페이스 예측가능성** — do the name and signature match what the code actually does?
5. **비동기 UX** — are loading, error, and empty states designed, not incidental?
6. **숨은 동작** — are there side effects the caller can't see from the call site?

Full detail for each lens — the question, a 3-5 item checklist, and one before/after example drawn from real code — is in [references/lenses.md](references/lenses.md).

## Output

Two things, always:

1. **Inline findings** — surfaced in the response, one per issue, each naming its lens.
2. **A written report** at `<repo>/docs/reviews/YYYY-MM-DD-<주제>.md`. Header block at the top:

```markdown
# <주제>

- 일시: YYYY-MM-DD
- 대상 범위: <git diff main...HEAD | 파일 목록 | 커밋 범위 | PR 번호>
- 리뷰어: fe-review
```

Followed by findings grouped by lens, each with a reason and (where useful) a suggested fix. Findings the diff doesn't trigger for a given lens are omitted, not padded in as "no issues."

## 하지 않는 것

- **스타일·포매팅 지적 안 함** — 들여쓰기, 세미콜론, import 순서, 줄바꿈 같은 것은 린터·포매터의 몫이다. 그 도구가 잡을 것을 이 리뷰가 다시 나열하지 않는다.
- **취향 차이를 결함으로 포장하지 않음** — "나라면 이렇게 안 짰다"는 근거가 아니다. 지적하려면 여섯 렌즈 중 하나에 걸리는 구체적 이유를 댄다.
- **근거 없는 추측 안 함** — diff 에 없는 코드의 동작을 추정해 지적하지 않는다. 확신이 없으면 질문형으로 쓰거나, 확인이 필요하다고 명시한다.

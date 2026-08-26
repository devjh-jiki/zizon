---
name: implement
description: Implement a piece of work from a PRD, a set of issues, or vertical slices — the bridge from an agreed spec to committed code. Use when the user says "이거 구현해줘", "이슈대로 만들어줘", "implement this PRD/issue/slice", "build the spec", or has a written plan ready to execute. This is for executing an already-agreed spec — if the spec is vague or unwritten, use product-spec-builder / to-prd first; if the work is exploratory throwaway, use prototype.
disable-model-invocation: true
---

# implement

합의된 스펙 — PRD, 이슈 묶음, 또는 수직 슬라이스 — 을 커밋된 테스트 코드로 바꾼다. `product-spec-builder`/`to-prd` → `to-issues` → `prototype` → **implement** 파이프라인의 마지막 구간이다: 사고는 끝났으니, 다시 논쟁하지 말고 만든다.

## 시작 전

구현할 스펙이 실제로 있는지 확인한다(**input contract**). PRD/이슈가 모호하거나 없으면 지어내지 말고 — 그렇게 말하고 `product-spec-builder` 나 `to-prd` 로 안내한다. 아이디어가 아직 탐색 단계면 `prototype` 으로 안내한다. 실행할 구체적 대상이 있을 때만 진행한다.

## 과정

1. **합의된 seam 에서 테스트 먼저.** `tdd` 스킬의 규율을 적용한다 — 한 번에 한 수직 슬라이스, red → green, 공개 인터페이스로 테스트, 각 동작이 반드시 필요해지도록 입력을 고른다. "사전 합의된 seam 에서"란: 스펙/이슈가 이미 지정한 seam 을 쓰라는 뜻 — 구현 도중에 새 seam 을 발명하지 않는다. 스펙이 seam 을 안 정했으면 가장 높은 깔끔한 곳을 골라 명시한다.
2. **진행하며 피드백 루프를 타이트하게.** 프로젝트에 타입 체커가 *있으면* 자주 돌리고, 작업 중인 단일 테스트 파일을 매 사이클마다 돌린다. (플레인 JS·무타입 레포는 typecheck 단계가 없다 — 건너뛰되 없다고 실패하지 않는다.)
3. **끝에 전체 스위트를 한 번** 돌려 슬라이스 간 회귀를 잡는다.
4. **스펙 대비 자기 검토.** 완료 = 모든 수용 기준이 seam 을 통과하는 테스트를 갖고, 스펙 밖의 것은 추가되지 않음. 기준을 명시적으로 훑는다; 데모·검증 가능한 체크가 없는 기능은 끝난 게 아니다.
5. **현재 브랜치에 커밋.** git 레포가 아니거나 사용자가 아직 커밋을 요청 안 했으면, 커밋하지 말고 무엇을 커밋할지(파일 + 메시지) 말한다.

이 단계들은 형제 스킬(`tdd` 는 루프, `to-prd`/`to-issues` 는 입력)에 기댄다. 환경이 이들을 슬래시 명령으로 연결해 뒀으면 쓰고, 아니면 밑바탕 능력 — TDD 하기, 검토하기, 커밋하기 — 이 핵심이지 명령이 핵심이 아니다.

## 오너 / 리더십 렌즈

CEO/CTO/CFO/PM 를 겸하는 개발자에게, 구현은 스펙의 약속이 현금화되는 곳이다:

- **스펙이 계약이다; 코딩하면서 조용히 재협상하지 마라.** 키보드에서 발명한 스코프 크리프가 가장 비싸다 — 테스트·리뷰·예산 없이 나간다. 현실이 스펙과 충돌하면 멈추고 알려라, 몰래 "개선"하지 말고.
- **통과한 수용 기준 하나가 전달된 가치의 단위다.** 작성한 줄 수나 쓴 시간이 아니라 기준 대비로 완료를 추적한다. 그게 인계하거나 손 떼는 것도 가능하게 한다.
- **타이트한 루프가 곧 처리량이다.** red→green 사이클이 빠를수록 세션당 더 많은 슬라이스가 나간다. 느리거나 없는 테스트 루프가 진짜 병목이지 타이핑 속도가 아니다.

## 출처

[mattpocock/skills `implement`](https://github.com/mattpocock/skills/tree/main/skills/engineering/implement) (MIT) 에서 가져와 확장. THIRD_PARTY_NOTICES.md 참고.

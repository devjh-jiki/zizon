---
name: resolving-merge-conflicts
description: Resolve an in-progress git merge or rebase conflict by recovering each side's intent and preserving both where possible. Use when the user has a conflicted merge/rebase, says "머지 충돌 해결", "리베이스 충돌", "conflict 났어", "fix this merge conflict", or git reports "CONFLICT (content)". For starting fresh branch work this isn't it; this is specifically for an already-conflicted tree.
---

# resolving-merge-conflicts

각 side 가 *왜* 코드를 바꿨는지 이해해 충돌을 푼다, hunk 를 기계적으로 고르지 말고. 항상 해소한다; 절대 `--abort` 도 `--skip` 도 하지 않는다(둘 다 작업을 버린다).

## 단계

1. **현재 상태 파악.** merge 인가 rebase 인가? `git status` 와 `git log --oneline --graph` 를 돌리고 충돌 파일을 연다. **어느 쪽이 어느 쪽인지 안다** — `merge` 에서는 `HEAD`/`<<<<<<< ours` 가 현재 브랜치, `theirs` 가 들어오는 브랜치; `rebase` 에서는 **반전된다** — `HEAD` 는 리베이스 *대상* 브랜치이고, `>>>>>>>` 쪽이 재생되는 내 커밋이다. 이걸 거꾸로 아는 게 가장 흔한 해소 오류다.

2. **각 충돌의 primary source 를 찾는다.** 각 변경이 왜 이뤄졌고 원래 의도가 뭔지 깊이 이해한다 — 커밋 메시지(`git log`/`git show` 양쪽), PR, 이슈를 읽는다. 각 side 를 merge base(`git merge-base`)와 diff 해서 최종 텍스트가 아니라 각 side 가 실제로 바꾼 것을 본다.

3. **각 hunk 를 해소한다.** 가능하면 양쪽 의도를 보존한다 — 고르기 전에 각 변경을 *기능적으로 무엇을 하나* vs *어떻게 읽히나* 로 분리한다; 스타일만의 충돌은 종종 공존 가능하다(예: 문구 변경과 추가된 장식은 직교라 둘 다 살아남는다). 진짜 양립 불가면 merge 의 명시된 목표에 맞는 쪽을 고르고 트레이드오프를 적는다; 목표가 명시 안 됐으면 가장 손실 적은 해소를 기본으로 하고 그렇게 말한다. **새 동작을 발명하지 않는다** — 살아남은 모든 조각은 한쪽으로 추적돼야 한다.

4. **프로젝트의 자동 검사를 돌린다.** 발견해 순서대로 — 보통 typecheck, 그다음 tests, 그다음 format — 돌리고 merge 가 깨뜨린 것을 고친다. 레포에 설정된 검사가 없으면 그렇게 말하고 최소 스모크 체크(예: 바뀐 코드를 한 번 로드/실행)로 폴백한다; 테스트 스위트를 지어내지 않는다.

5. **merge/rebase 를 끝낸다.** 전부 스테이지하고 계속한다(merge 는 `git commit`, rebase 는 `git rebase --continue`), 모든 커밋이 재생될 때까지. `--continue` 가 커밋 메시지 에디터를 열 수 있다 — 비대화형/에이전트 맥락에서는 `GIT_EDITOR=true`(또는 가능한 곳에선 `--no-edit`)를 설정해 hang 되지 않게 한다. `git status` 로 진행 중인 rebase/merge 가 없고 트리가 깨끗한지 확인한다.

## 오너 / 리더십 렌즈

CEO/CTO/CFO/PM 를 겸하는 개발자에게, 충돌은 두 의도의 충돌이다 — 텍스트가 아니라 의도를 해소하라:

- **눈먼 hunk 선택은 누군가의 작업을 조용히 삭제한다.** 나쁜 해소의 비용은 merge 가 아니라, 프로덕션에서야 발견되는 사라진 기능이다. 커밋 메시지에서 의도를 복원하는 건 그에 대한 싼 보험이다.
- **한쪽을 버릴 땐 트레이드오프를 기록하라.** 커밋 메시지의 "merge 가 Z 를 노렸기에 Y 대신 X 를 유지함" 한 줄이 다음 사람의 충돌 재발견을 — 그리고 당신의 의도적 선택을 "고치는" 일을 — 막는다.
- **어려운 충돌을 피하려고 `--abort` 하지 마라.** abort 는 이미 한 분석을 버린다; 또 치르게 된다. 해소까지 밀어붙여라.

## 출처

[mattpocock/skills `resolving-merge-conflicts`](https://github.com/mattpocock/skills/tree/main/skills/engineering/resolving-merge-conflicts) (MIT) 에서 가져와 확장. THIRD_PARTY_NOTICES.md 참고.

# zizon — 개인 에이전트 자산 단일 소스 설계

- 작성일: 2026-08-25
- 상태: 설계 승인 대기
- 대상 레포: `devjh-jiki/jiki` → `devjh-jiki/zizon` (개명 예정)

## 1. 배경

에이전트 자산(스킬·MCP·에이전트·훅)이 세 곳에 흩어져 있고 서로를 모른다.

| 위치 | 내용 |
|---|---|
| `~/.claude/` | 전역 MCP 4개, 플러그인 6개, 에이전트 3개, 훅 6개, settings.json |
| dev-hub 레포 | 스킬 35개 (플러그인 5묶음으로 선언되었으나 **한 번도 설치된 적 없음**) |
| 각 프로젝트 `.claude/` | 레포별 커맨드·스킬·룰 |

결과적으로 dev-hub의 스킬 35개는 전부 사용 불가 상태였고, 전역 설정은 손으로 쌓여 재현 불가능한 상태다. Claude 성능이 올라가면서 상당수 스킬이 중복이 되었다는 판단도 있다.

## 2. 목표 / 비목표

**목표**
- `git clone && ./bootstrap.sh` 로 새 맥에서 작업 환경을 재현한다.
- 진짜 쓰는 것만 남긴다 — 판단 근거는 취향이 아니라 사용량과 중복이다.
- 공개 레포에 올려도 되는 것과 아닌 것의 경계를 명확히 한다.

**비목표**
- Codex·Cursor·VSCode·OpenCode 지원 (Claude Code 전용으로 확정)
- 팀 공유·조직 배포 (개인용)
- 프로젝트별 `.claude/` 를 zizon 이 관리하는 것 (프로젝트 스코프 MCP 배치만 예외)

## 3. 확정된 결정

| # | 결정 | 비고 |
|---|---|---|
| D1 | 단일 공개 레포로 관리, 민감부는 익명화·ENV 변수화 | D5 로 부분 수정됨 |
| D2 | Claude Code 전용 | `runtimes/`, `.agents/` 삭제 근거 |
| D3 | 부트스트랩 포함 — 머신 전체를 재현 | 서드파티 플러그인·settings.json 까지 |
| D4 | 접근 A: GitHub 마켓플레이스 + 얇은 부트스트랩 | `--dev` 플래그로 로컬 마켓플레이스 전환 |
| D5 | review 에이전트는 **원점 재작성** (익명·다관점) | 아래 §4 참조 |
| D6 | 레포명 `zizon` — GitHub 레포명까지 변경 | star 0 / fork 0 이라 비용 없음 |
| D7 | prune 은 공격적 — superpowers 와 겹치면 자른다 | |
| D8 | learning 버킷 유지 → 6번째 분류로 승격 | |
| D9 | impeccable 은 벤더링하지 않고 추천 설치 | `diagram-design` 선례 따름 |

## 4. D5 상세 — review 자산의 출처 문제

기존 `fe-review-bot` 의 페르소나·에이전트는 wallcheon private 레포 코드와 동료(dev-hobin, Seung-wan)의 코멘트 원문에서 증류되었다. 해당 레포 README 는 배포를 금지하고, 협업자 추가 전 본인 동의를 요구한다.

**이름을 익명화해도 해결되지 않는다.** few-shot 예시 본문에 원 코드 diff 와 코멘트가 남기 때문이다. 따라서:

- 기존 `fe-review-bot` 레포와 `~/.claude/agents/` 의 에이전트 3개는 **현 상태로 로컬 유지**한다. zizon 으로 이관하지 않는다.
- zizon 의 `fe-review` 는 wallcheon 자료 0에서 새로 작성한다. 인물 재현을 포기하는 대신 관점을 6축으로 명시한다.
- few-shot 예시는 본인 소유 저장소(jjan `apps/web`, kalyx, jihoon-blog)에서만 발췌한다.

## 5. 판단 근거 데이터

388개 세션 / 523MB 트랜스크립트에서 `"name":"mcp__*"` tool_use 블록과 Skill 호출을 집계했다.

**MCP — 총 299회**

| 서버 | 호출 | 조치 | 근거 |
|---|---:|---|---|
| sentry | 270 | 프로젝트 스코프로 강등 | 전부 jihoon-blog·kalyx |
| figma | 16 | 프로젝트 스코프로 강등 | 전부 mutal |
| agentmemory | 7 | 유지 | 가치는 훅에 있음 |
| serena | 6 | 제거 | 388세션 6회 |

**플러그인 — Skill 호출**

| 플러그인 | 호출 | 조치 |
|---|---:|---|
| superpowers | 50+ | 유지 |
| watch | 3 | 제거 |
| agentmemory | 1 | 유지 (훅 목적) |
| understand-anything | 0 | 제거 |
| karpathy-skills | 0 | 제거 |
| gitkraken-hooks | 스킬 없음 | 제거 |

**측정의 한계**: dev-hub 스킬 35개는 전부 0회이나, 이는 플러그인이 설치된 적 없기 때문이다. **dev-hub 내부의 컷 판단에 사용량을 근거로 쓰지 않았다** — 중복과 분류 적합도로만 판단했다.

**부수적으로 발견한 버그**: agentmemory 훅이 이중 등록되어 있다. 플러그인이 `hooks/hooks.json` 에서 `${CLAUDE_PLUGIN_ROOT}` 로 12개 이벤트를 등록하는데, `~/.claude/settings.json` 에 같은 스크립트를 절대경로로 가리키는 6개가 또 있다. SessionStart·UserPromptSubmit·PreToolUse·PreCompact·Stop·SessionEnd 가 매 세션 두 번 실행된다. 부트스트랩 purge 단계에서 settings.json 쪽을 제거한다.

## 6. 최종 구성

### 6.1 분류 — 6개

| 분류 | 출처 계보 |
|---|---|
| token | caveman, ponytail, i-have-adhd |
| design | taste-skill (impeccable 은 외부 추천) |
| planning | mattpocock 계열 중 superpowers 미중복분 |
| review | 신규 |
| testing | goldbergyoni (MIT) + 기존 |
| learning | 기존 |
| util | 분류가 아닌 유틸 버킷 — 안전장치·git 보조 |

### 6.2 남기는 스킬 — 19개 (기존 유지 16 + 신규 3)

| 분류 | 스킬 | 상태 |
|---|---|---|
| token | `terse-output` `context-budget` `lazy-code` | 이관 |
| token | `i-have-adhd` | **신규 동기화** (ayghri/i-have-adhd) |
| design | `anti-slop-frontend` | 이관 |
| planning | `grill-me` `to-prd` `to-issues` `implement` `codebase-design` `domain-modeling` | 이관 |
| review | `fe-review` | **신규 작성** |
| review | `be-review` | `go-backend-review` 개명 + 캐논 슬롯 활성화 |
| testing | `js-testing` | **신규 작성** |
| testing | `webapp-testing` | 이관 |
| learning | `open-source-reverse-engineering-coach` `technical-book-coach` | 이관 |
| util | `git-guardrails` `resolving-merge-conflicts` | 이관 |

### 6.3 제거하는 스킬 — 19개

검산: 기존 35 = 유지 16 + 제거 19. 최종 19 = 유지 16 + 신규 3(`i-have-adhd`, `fe-review`, `js-testing`).

**superpowers 중복 (5)** — `verification-before-completion`(이름 동일) · `handoff`(agentmemory:handoff 와 충돌) · `tdd`(↔test-driven-development, 66줄 vs 320줄) · `diagnosing-bugs`(↔systematic-debugging, 69줄 vs 283줄) · `writing-great-skills`(↔writing-skills, 95줄 vs 679줄)

네 쌍의 SKILL.md 본문을 대조한 결과 `implement` 는 컷에서 **철회**했다. `executing-plans` 는 *작성된 플랜* 을 체크포인트와 함께 실행하는 반면 `implement` 는 *PRD·이슈* 에서 코드로 가는 다른 진입점이며, 자르면 `to-prd → to-issues → 코드` 사슬이 끊긴다. 나머지 셋은 superpowers 쪽이 4~7배 상세하고 위상이 겹쳐 컷을 유지한다.

**분류 밖 / 내부 중복 (14)** — `biz-opportunity-scout` `marketing-copy` `product-spec-builder` `eval-harness` `improve-codebase-architecture` `prototype` `iterative-retrieval` `grill-with-docs`(↔grill-me) `council` `recency-research` `document-with-research` `setup-pre-commit` `write-blog-post` `design-system`

`design-system` 은 Meta 의 Astryx(`astryx.atmeta.com`)를 9군데 하드코딩하고 있고, 해당 `xds` MCP 는 money-flow 레포와 함께 삭제되어 현재 동작하지 않는다.

### 6.4 최종 도구 수

| | 이전 | 이후 |
|---|---:|---:|
| 전역 MCP | 4 | 1 (agentmemory 제거는 결론이 안 나서 보류, 그대로 유지) |
| 플러그인 | 6 | 3 (superpowers, agentmemory, zizon) |
| 마켓플레이스 | 6 | 3 |
| 스킬 (zizon) | 35 (미설치) | 19 (설치됨) |
| 전역 에이전트 | 3 | 3 (로컬 유지, zizon 밖) |

## 7. 레포 구조

```
zizon/
├── .claude-plugin/
│   ├── marketplace.json      # 플러그인 1개 선언 (기존 5묶음 → 1개)
│   └── plugin.json
├── skills/
│   ├── token/ design/ planning/ review/ testing/ learning/ util/
├── bootstrap/
│   ├── manifest.json         # 원하는 상태 선언
│   └── bootstrap.sh          # 멱등 적용
├── docs/
├── prompts/ snippets/ templates/ learning/ai/    # 스킬 아닌 개인 자산, 유지
├── README.md + README.en.md
├── AGENTS.md + AGENTS.ko.md
└── THIRD_PARTY_NOTICES.md
```

**삭제 대상**: `.agents/skills/`(심볼릭 링크 34개) · `runtimes/{codex,cursor,vscode,opencode}/` · `runtimes/claude-code/mcp/` · `mcp/` — D2(Claude Code 전용)와 전역 MCP 0개 결정으로 전부 무의미해짐. `runtimes/claude-code/skills/git-guardrails` 는 `skills/util/` 로 이동.

## 8. 신규 스킬 설계

### 8.1 `review/fe-review`

- **입력**: 기본 `git diff main...HEAD`. 파일·커밋 범위·PR 지정 가능.
- **렌즈 6축**:

| 렌즈 | 묻는 것 |
|---|---|
| 요구사항 추적성 | 이 코드가 무슨 요구사항을 만족시키는지 읽히나 |
| 추상화 비용 | 이 추상화가 벌어들이는 것보다 비싸지 않나 |
| 상태의 위치 | 전역·컨텍스트로 올라간 상태가 정말 그 자리여야 하나 |
| 인터페이스 예측가능성 | 이름과 시그니처가 실제 동작과 일치하나 |
| 비동기 UX | 로딩·에러·빈 상태가 설계되었나 |
| 숨은 동작 | 호출자가 모르는 부수효과가 있나 |

- **출력**: 인라인 지적 + `<repo>/docs/reviews/YYYY-MM-DD-<주제>.md`
- **형태**: 서브에이전트가 아니라 **스킬**. 호출해도 타인 코드가 컨텍스트에 유입되지 않는다.
- **참조 파일**: `references/lenses.md` 에 렌즈별 체크리스트와 few-shot(본인 저장소 발췌).

### 8.2 `review/be-review`

- 기존 `go-backend-review` 의 project-canon adapter slot 을 실제로 구현한다.
- **공개 본문**: Go 백엔드 리뷰 원칙 — 경계, 에러 래핑, 컨텍스트 전파, 트랜잭션 경계, 동시성, 관측성.
- **캐논 슬롯**: `<repo>/docs/review-canon.md` 가 있으면 읽어 프로젝트 규칙을 우선 적용한다. **(참고: 이 고정 파일명 슬롯은 실제 구현에서 project adapter 계약(예: 프로젝트 스코프 agent 파일)으로 대체됐다. 자세한 건 `skills/review/be-review/SKILL.md` 의 "Project adapter contract" 참고.)**
- **jjan 캐논은 jjan 레포에 생성한다.** jjan 은 private(`jiji-hoon96/jjan`)이므로 zizon 에 들어가지 않는다. 초안은 기존 `docs/reviews/*-be.md` 5개에서 반복 지적 패턴을 추출해 만든다.

### 8.3 `testing/js-testing`

- **출처**: `goldbergyoni/javascript-testing-best-practices` (MIT). 50+ 항목, 6개 섹션.
- **증류 원칙**: 전부 옮기지 않는다. **판단이 갈리는 항목만** 남긴다 — 전량 이식은 원문 링크와 가치가 같다.
- **역할 경계**:
  - `js-testing` — 무엇을 어느 층위에서 테스트할지 **판단**
  - `webapp-testing` — Playwright 로 **구동·검증**
  - `superpowers:test-driven-development` — TDD 루프 **진행**
- `THIRD_PARTY_NOTICES.md` 에 MIT 고지를 추가한다.

`i-have-adhd` 도 MIT(Copyright (c) 2026 Ayoub Ghriss) 로 확인했다. 마찬가지로 `THIRD_PARTY_NOTICES.md` 에 고지하고, `.github/workflows/sync-upstream-skills.yml` 의 upstream 목록(현재 7개)에 등록해 자동 동기화 대상에 포함한다.

## 9. 부트스트랩 설계

`bootstrap/manifest.json` 이 원하는 상태를 선언하고 `bootstrap.sh` 가 멱등 적용한다. 재실행해도 결과가 같아야 한다.

**3단계**

1. **purge** — 마켓플레이스 4개(understand-anything, karpathy-skills, claude-video, gitkraken) 제거 · 전역 MCP 3개(serena, figma, sentry) 제거 · `settings.json` 의 중복 훅 6개 제거
2. **install** — 마켓플레이스 3개 등록 후 플러그인 3개 설치 (superpowers, agentmemory, zizon)
3. **project-scope** — sentry 를 jihoon-blog·kalyx 의 `.mcp.json` 에, figma 를 mutal 에 배치

**사용 CLI**: `claude plugin marketplace add|remove|update` · `claude plugin install` · `claude mcp add|remove`

비대화형 실행은 `claude mcp remove` 만 실제로 확인했고 나머지는 `--help` 로 인터페이스만 확인했다. 특히 `claude plugin install` 은 새 마켓플레이스 신뢰 확인 프롬프트가 뜰 가능성이 있어, 무인 실행 여부를 §11 에서 검증한다.

**시크릿**: 실제 값은 `~/.config/zizon/env` 에 두고 셸 프로파일에서 source 한다. 레포에는 `env.example` 만 커밋한다. `.mcp.json` 에서는 `${FIGMA_API_KEY}` 형태로 참조한다.

**개발 모드**: `bootstrap.sh --dev` 는 zizon 마켓플레이스를 GitHub 대신 로컬 디렉토리로 등록해, 편집→반영 루프에서 push 를 생략한다.

## 10. 마이그레이션 순서

1. 스킬 19개 삭제, 남길 16개를 새 버킷 구조로 이동
2. `.agents/`, `runtimes/{codex,cursor,vscode,opencode}`, `mcp/` 삭제
3. `.claude-plugin/marketplace.json` 을 플러그인 1개 구조로 재작성
4. 신규 스킬 3개 작성 (`fe-review`, `be-review`, `js-testing`), `i-have-adhd` 동기화
5. `bootstrap/` 작성
6. README·AGENTS 한/영 쌍 갱신 — 레포명·설치 명령·인덱스 표
7. GitHub 레포 `jiki` → `zizon` 개명, 로컬 폴더명·remote 갱신
8. `bootstrap.sh` 실행해 실제 적용 및 검증

## 11. 검증 기준

- `bootstrap.sh` 를 연속 2회 실행해 두 번째 실행이 아무것도 바꾸지 않는다 (멱등성)
- 새 세션에서 `/plugin` 목록이 정확히 3개이고, 전역 MCP 가 1개다(agentmemory 제거는 결론이 안 나서 보류, 그대로 유지)
- zizon 스킬 19개가 스킬 목록에 뜬다
- agentmemory 훅이 이벤트당 1회만 실행된다
- `check-doc-pairs.yml` 통과
- jihoon-blog 에서 sentry MCP 가, mutal 에서 figma MCP 가 프로젝트 스코프로 잡힌다
- `claude plugin install` 과 `claude plugin marketplace remove` 가 프롬프트 없이 완주한다
- **sentry OAuth 승계 확인** — sentry 는 최다 사용(270회) MCP 이고 인증 캐시(`~/.claude/mcp-needs-auth-cache.json`)가 user 스코프의 서버명으로 키잉되어 있다. 프로젝트 스코프로 옮겼을 때 인증이 승계되는지 **jihoon-blog 한 곳에서 먼저** 확인한 뒤 kalyx 에 적용한다. 재인증이 프로젝트마다 필요하다면 강등 자체를 재검토한다.

## 12. 리스크와 미결

| 항목 | 내용 |
|---|---|
| 되돌리기 | 삭제되는 스킬 19개는 git 히스토리에 남는다. upstream 원본도 살아있다. |
| agentmemory 중복 | 내장 파일 메모리(`MEMORY.md`)와 역할이 겹친다. 이번엔 둘 다 유지하고, 한쪽으로 줄일지는 추후 판단. |
| CLI 의존 | 부트스트랩이 `claude` CLI 인터페이스에 의존한다. CLI 변경 시 수정 필요. |
| fe-review 품질 | 인물 재현을 포기했으므로 기존 봇 대비 "그 사람 같음" 은 떨어진다. 렌즈 6축의 실효성은 실사용으로 검증해야 한다. |
| 미결 | 없음 — `AGENTS.md`/`AGENTS.ko.md`/`CLAUDE.md` 의 문서 페어 예외 서술을 CI 실제 동작과 일치시키는 작업은 최종 수정 웨이브(`08aff14`)에서 완료했다. |

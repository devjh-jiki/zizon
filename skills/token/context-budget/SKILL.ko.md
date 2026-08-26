---
name: context-budget
description: >
  Audit how much of the context window is spent before the user even types —
  on agents, skills, MCP servers/tools, rules, and AGENTS.md/CLAUDE.md — then
  produce a ranked list of what to cut for the biggest token savings. Use when a
  session feels sluggish or output quality is slipping, after adding a bunch of
  skills/agents/MCP servers, when planning to add more and wondering if there's
  room, or when the user says "내 설정이 토큰 얼마나 먹는지 감사해줘",
  "MCP/스킬 정리하고 싶어", "설정이 무거워", "context bloat", "audit my setup",
  "how much does my config cost before I even type", "do I have room to add
  another MCP server". This audits the STANDING overhead of a CONFIG/SETUP
  present before you type anything — not the token cost of an ongoing
  conversation's messages, not the context you feed a subagent (that is
  iterative-retrieval), and not shortening the model's replies (that is
  terse-output).
---

# Context Budget

로드된 에이전트, 스킬, MCP 툴 스키마, 룰 파일 하나하나가 대화가 시작되기도 전에 컨텍스트를 쓴다. 그것은 조용히 쌓인다: 여기 스킬 하나, 저기 MCP 서버 하나, 이 세션이 절대 건드리지 않을 것들에 창의 한 덩어리가 사라질 때까지. 이 스킬은 그 상시 오버헤드를 측정하고, 순위 매겨서 뭘 잘라야 하는지 알려준다.

## 언제 terse-output 대신 이걸

`terse-output` 은 모델이 *답하는* 것을 줄인다. **context-budget** 은 누가 뭐라 말하기도 전에 세팅이 *비용으로 무는* 것을 줄인다. 하나는 응답 길이, 이건 네 설정의 고정 세금이다. 둘은 조합되지만 다른 문제를 푼다.

## 동작 방식

### Phase 1: 인벤토리
각 컴포넌트 소스를 스캔하고 토큰 추정(산문 `words × 1.3`, 코드 많은 파일 `chars / 4`):

- **에이전트 / 서브에이전트** — 정의당 토큰. 에이전트의 `description` 은 그 에이전트를 안 써도 *모든* 태스크 디스패치에 로드된다. 플래그: 정의 ~200줄 초과, description ~30단어 초과.
- **스킬** — `SKILL.md` 당 토큰. 항상 로드되는 건 description 뿐이고 본문은 호출 시 로드됨에 유의. 플래그: `SKILL.md` ~400줄 초과. 동일한 미러 복사본은 중복 집계 피하려 건너뛴다.
- **MCP 서버** — 서버 수와 총 툴 수. 툴 스키마당 대략 ~500토큰 추정. 플래그: 툴 ~20개 초과 서버, 이미 있는 CLI(`gh`, `git`, `npm` 등)를 감싸기만 하는 서버.
- **룰 / 지침** — 룰·지침 파일당 토큰. 플래그: 파일 간 중복, AGENTS.md 를 복제하는 내용.
- **AGENTS.md / CLAUDE.md 체인** — 프로젝트 + 유저 레벨 파일 합산 토큰. 플래그: 합계 ~300줄 초과.

### Phase 2: 분류
모든 컴포넌트를 버킷으로:

| 버킷 | 기준 | 행동 |
|--------|----------|--------|
| **항상 필요** | AGENTS.md 에 참조, 활성 커맨드 백업, 현 프로젝트에 매치 | keep |
| **가끔 필요** | 도메인 특정, 참조 안 됨, 간헐적 | on-demand / lazy-load 로 |
| **거의 안 씀** | 참조 없음, 중복, 프로젝트 매치 없음 | 제거 |

### Phase 3: 이슈 탐지
- **부풀린 에이전트 description** — 긴 `description` 필드가 모든 태스크 디스패치에 딸려 감.
- **무거운 에이전트/스킬** — 과대한 정의가 매 spawn 마다 컨텍스트를 부풀림.
- **중복 컴포넌트** — 에이전트를 복제하는 스킬, AGENTS.md 를 복제하는 룰.
- **MCP 과다 구독** — 단일 최대 레버. 서버가 많거나, 공짜 CLI 툴을 감싸는 서버.
- **지침 부풀림** — 장황하거나 낡은 AGENTS.md/CLAUDE.md 섹션.

### Phase 4: 리포트
```
Context Budget Report
총 상시 오버헤드: ~XX,XXX 토큰
창: ~XXX,XXX  →  실효 가용: ~XX%

컴포넌트          수     토큰
Agents           N       ~X,XXX
Skills           N       ~X,XXX
Rules/AGENTS.md  N       ~X,XXX
MCP tools        N       ~XX,XXX

이슈 (절감액 순):
1. [행동] → ~X,XXX 토큰
2. [행동] → ~X,XXX 토큰
3. [행동] → ~X,XXX 토큰

잠재 절감: ~XX,XXX (오버헤드의 ~XX%)
```
Verbose 모드: 파일별 토큰 수, 가장 무거운 파일의 줄별 내역, 중복 컴포넌트 간 겹치는 줄, MCP 툴별 스키마 크기 목록 추가.

## 예시

**감사** — "context 감사해줘" → 세팅 스캔, 예: 에이전트 16(~12k), 스킬 28(~6k), MCP 툴 87(~44k), AGENTS.md(~1k); 무거운 에이전트 3개와 MCP 서버 14개(3개 CLI 대체 가능) 플래그; 최대 절감: MCP 서버 3개 제거 → 약 -27k 토큰.

**확장 전 점검** — "MCP 5개 더 붙일 건데 여유 있어?" → 현 오버헤드 ~33%; +5 서버(~50 툴) 약 +25k → ~45% 로; CLI 대체 가능 서버 2개 먼저 제거 권장.

## 베스트 프랙티스
- **MCP 가 최대 레버** — 툴 스키마 하나가 대략 ~500토큰; 30툴 서버가 네 스킬 전부 합친 것보다 무거울 수 있다.
- **에이전트 description 은 항상 로드** — 절대 호출 안 하는 에이전트도 매 태스크 디스패치에 description 값을 낸다.
- **스킬 본문은 아니다** — 스킬 `SKILL.md` 본문은 호출 시 로드; 상시 비용은 description 뿐. 스킬은 description 길이로, 에이전트는 전체 크기로 판단하라.
- **정직하게 추정** — 산문 `words × 1.3`, 코드 `chars / 4`.
- **변경 후 감사** — 에이전트·스킬·MCP 서버를 추가한 뒤 돌려라. 서른 개가 아니라 한 개일 때 크리프를 잡게.

## 경계
이건 *세팅* 의 고정 오버헤드(에이전트·스킬·MCP·룰)를 감사한다. 모델의 답변을 줄이지 않고(그건 `terse-output`), 돌아가는 대화 메시지 자체의 토큰 비용을 재지 않는다. "시작하기도 전에 내 설정이 나한테 얼마를 물리나" 가 질문일 때 꺼내고, 더 추가하기 전에 실행하라.

## Attribution

[affaan-m/ecc](https://github.com/affaan-m/ecc) (MIT) 에서 **적응**: 4-phase 감사(inventory → classify → detect → report), 토큰 추정 휴리스틱(`words × 1.3`, `chars / 4`), 항상/가끔/거의 안 씀 버킷, 리포트 형태와 verbose 모드, 핵심 통찰("MCP 가 최대 레버", "에이전트 description 은 항상 로드")을 보존했다. 이 레포에 맞게 재작성 — ECC 고유 디렉토리 경로(`agents/*.md`, `rules/**`, `.mcp.json`)를 AGENTS.md 를 포함한 도구 무관 용어의 에이전트/스킬/MCP/룰로 일반화했고, `terse-output` 과의 경계를 추가하고 한국어 트리거를 넣었다. THIRD_PARTY_NOTICES.md 참조.

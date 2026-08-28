# Skills

> English: [README.md](./README.md)

매일 쓰는 나만의 에이전트 스킬 모음. 공개 [Agent Skills](https://agentskills.io) 표준을 따르며 단일 Claude Code 플러그인 `zizon` 으로 배포합니다.

## 설치

```
/plugin marketplace add devjh-jiki/zizon
/plugin install zizon@zizon
```

## 버킷

| 버킷 | 용도 |
|------|------|
| `token/` | 토큰/컨텍스트 소비 절감. 초압축 출력, 게으른 코드, 컨텍스트 예산 감사 |
| `design/` | 프론트엔드 디자인 품질과 취향 |
| `planning/` | 논의를 스펙·이슈·도메인 모델로 바꾸고 실행 |
| `review/` | 명시적 렌즈로 diff 리뷰 |
| `testing/` | 무엇을·어떻게 테스트할지 판단 |
| `learning/` | 코드·책을 코칭 방식으로 학습 |
| `util/` | git 안전장치와 충돌 해소 |
| `writing/` | 사람이 읽을 글. 아티클, 도메인 문서, 문서 거버넌스 |

## 등재된 스킬

### Token

**Model-invoked** (작업에 맞으면 에이전트가 자동 사용)

- [terse-output](./token/terse-output/SKILL.ko.md). 초압축 커뮤니케이션 모드; lite/full/ultra (JuliusBrussee/caveman 적응)
- [context-budget](./token/context-budget/SKILL.ko.md). 에이전트/스킬/MCP/룰의 상시 컨텍스트 오버헤드를 감사하고 뭘 자를지 순위화 (affaan-m/ecc 적응)
- [lazy-code](./token/lazy-code/SKILL.ko.md). 실제로 동작하는 가장 게으른 해법 강제 (YAGNI 사다리, 의존성보다 표준 라이브러리/네이티브); lite/full/ultra (DietrichGebert/ponytail 적응)

**User-invoked** (사람이 `/명령`으로만 실행)

- [i-have-adhd](./token/i-have-adhd/SKILL.ko.md). 모든 응답을 다음 행동부터, 리스트 5개 캡, 군더더기 제거 모드로 재구성

### Design

**Model-invoked**

- [anti-slop-frontend](./design/anti-slop-frontend/SKILL.ko.md). AI가 만든 마케팅/랜딩/포트폴리오 프론트엔드가 템플릿처럼 안 보이게 (브리프 읽기, 세 다이얼, LLM 기본값 회피, 프리플라이트)

### Planning

**Model-invoked**

- [codebase-design](./planning/codebase-design/SKILL.ko.md). 깊은 모듈 설계 어휘
- [domain-modeling](./planning/domain-modeling/SKILL.ko.md). 도메인 모델을 능동적으로 구축·정밀화 (용어집 + ADR)

**User-invoked**

- [grill-me](./planning/grill-me/SKILL.ko.md). 계획·설계·의사결정·사업 아이디어를 스트레스 테스트하는 집요한 인터뷰 (mattpocock/skills 참고)
- [to-prd](./planning/to-prd/SKILL.ko.md). 현재 대화를 PRD 로 합성 (인터뷰 없음)
- [to-issues](./planning/to-issues/SKILL.ko.md). 계획/PRD 를 수직 슬라이스 이슈로 분해
- [implement](./planning/implement/SKILL.ko.md). 합의된 PRD/이슈/슬라이스를 커밋된 테스트 코드로 구현

### Review

**Model-invoked**

- [fe-review](./review/fe-review/SKILL.ko.md). 프론트엔드 diff 를 6렌즈(요구사항 추적성, 추상화 비용, 상태 위치, 인터페이스 예측가능성, 비동기 UX, 숨은 부작용)로 리뷰
- [be-review](./review/be-review/SKILL.ko.md). Go 백엔드 diff 를 아키텍처 경계, 데이터 무결성, 에러/보안 규율, Go 관용구로 리뷰 (프로젝트 캐논 어댑터 필요)

### Testing

**Model-invoked**

- [js-testing](./testing/js-testing/SKILL.ko.md). JS/TS 코드베이스에서 무엇을 어느 레벨에서 테스트할지 판단
- [webapp-testing](./testing/webapp-testing/SKILL.ko.md). Playwright 로 로컬 웹앱 구동·테스트 (정찰 후 행동)

### Learning

**Model-invoked** (학습 맥락이면 에이전트가 자동 사용)

- [open-source-reverse-engineering-coach](./learning/open-source-reverse-engineering-coach/SKILL.ko.md). 오픈소스를 역공학하며 아키텍처·인터페이스·트레이드오프를 배우는 코치
- [technical-book-coach](./learning/technical-book-coach/SKILL.ko.md). 기술 서적·문서를 코칭으로 학습 (영문 붙여넣기 시 한글 번역 + 코칭 분리)

### Util

**Model-invoked**

- [resolving-merge-conflicts](./util/resolving-merge-conflicts/SKILL.ko.md). merge/rebase 충돌을 양쪽 의도 복원으로 해소

**User-invoked / Claude Code hook**

- [git-guardrails](./util/git-guardrails/SKILL.ko.md). 위험한 git 명령을 막는 Claude Code PreToolUse hook 설치 (Claude Code 전용)

### Writing

**모델 호출**

- [article-writing](./writing/article-writing/SKILL.ko.md). 설득·교육 목적의 롱폼 글을 쓰고 구조·호흡·근거를 조인다
- [writing-domain-docs](./writing/writing-domain-docs/SKILL.ko.md). 도메인·설계 판단을 사람이 읽을 문서로 쓴다. 템플릿 문구·레포 재진술·출처 불명을 막는다
- [living-docs-governance](./writing/living-docs-governance/SKILL.ko.md). 오래 사는 문서 세트의 역할·정본·의도적 삭제를 관리한다

## upstream 동기화

[mattpocock/skills](https://github.com/mattpocock/skills) 등 검증된 외부 레포의 변경분은
`.github/workflows/sync-upstream-skills.yml` 가 매주 월요일 감지해 `.upstream/` 스냅샷을
**main 에 자동 커밋**합니다 (PR 없음). `.upstream/` 은 런타임에서 아무것도 소비하지 않는
참조용이라 승인 없이 갱신해도 안전합니다.

**단, 자동 커밋되는 것은 스냅샷뿐입니다.** `skills/` 의 스킬들은 복사본이 아니라 각색본이므로,
upstream 변경을 내 스킬에 반영할지는 직접 판단합니다.
`git diff <이전 sync 커밋>..HEAD -- .upstream/<owner>-<repo>` 로 무엇이 바뀌었는지 보고 고르세요.

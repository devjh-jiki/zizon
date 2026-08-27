# zizon

> English: [README.en.md](./README.en.md)

개발자로서 활용하는 모든 자산을 한곳에서 찾고 관리하는 **공개 메타레포 / 인덱스 허브**입니다.
"그거 어디 적어뒀더라"를 없애는 것이 목표입니다.

> 비공개 자산(사이드 프로젝트 wiki, 일상/여행 기록, 공개하기 애매한 학습 노트)은 별도
> 프라이빗 레포 `vault` 에서 관리합니다. 이 레포에는 공개 가능한 것만 둡니다.

## 인덱스

| 영역 | 위치 | 설명 |
|------|------|------|
| Skills | [`skills/`](./skills) | 나만의 에이전트 스킬. 8개 버킷, 22개. Claude Code 플러그인(zizon)으로 설치 |
| Bootstrap | [`bootstrap/`](./bootstrap) | 머신 셋업(마켓플레이스·플러그인·MCP 서버·hook)을 선언적 manifest 로 재현하는 멱등 적용 스크립트 |
| Prompts | [`prompts/`](./prompts) | 자주 쓰는 프롬프트 명령어 |
| Learning / AI | [`learning/ai/`](./learning/ai) | 프론트엔드 개발자 관점 AI 학습 로드맵 + 자료 + 기록 |
| Snippets | [`snippets/`](./snippets) | 자주 쓰는 코드/설정 스니펫 |

## 스킬 설치

Claude Code 플러그인 마켓플레이스에서 설치합니다.

```
/plugin marketplace add devjh-jiki/zizon
/plugin install zizon@zizon
```

### 외부 추천 플러그인

[`cathrynlavery/diagram-design`](https://github.com/cathrynlavery/diagram-design)은 아키텍처, 플로차트, 시퀀스, 데이터 모델 등 기술 다이어그램을 독립 HTML/SVG/PNG로 만드는 플러그인입니다. 이 레포에는 복사하지 않으며, 원본 플러그인을 직접 설치해 업데이트와 검증 체계를 그대로 따르는 방식을 권장합니다.

```text
/plugin marketplace add cathrynlavery/diagram-design
/plugin install diagram-design@diagram-design
```

[`pbakaus/impeccable`](https://github.com/pbakaus/impeccable)은 프론트엔드 산출물이 AI 특유의 디자인 슬롭처럼 보이지 않게 잡아내는 감지 규칙과 전용 명령을 제공하는 디자인 품질 도구입니다. 이 레포에도 복사하지 않으며, 원본을 직접 설치해 업데이트와 검증 체계를 그대로 따르는 방식을 권장합니다.

```text
/plugin marketplace add pbakaus/impeccable
/plugin install impeccable@impeccable
```

마케팅/랜딩/포트폴리오 UI 의 취향 판단은 [`anti-slop-frontend`](./skills/design/anti-slop-frontend) 스킬을 먼저 쓰고, 필요하면 impeccable 의 감지 규칙으로 다시 한번 확인하세요.

### 신뢰도 라벨

스킬은 검증 단계로 표시합니다:

- **Available** — 직접 테스트·검증 완료. 외부 설치 권장.
- **Review** — 평가 중. 검증되면 Available 로 승격.
- **Private** — 개인 셋업 전용. 마켓플레이스 미포함.

| 스킬 | 버킷 | 단계 | 설명 |
|------|------|------|------|
| [terse-output](./skills/token/terse-output) | token | Available | 정확도 유지하며 토큰 절감하는 초압축 출력; lite/full/ultra (JuliusBrussee/caveman 적응) |
| [context-budget](./skills/token/context-budget) | token | Available | 에이전트/스킬/MCP/룰 상시 컨텍스트 오버헤드 감사·순위화 |
| [lazy-code](./skills/token/lazy-code) | token | Available | YAGNI 사다리로 가장 게으른 해법 강제; lite/full/ultra (DietrichGebert/ponytail 적응) |
| [i-have-adhd](./skills/token/i-have-adhd) | token | Available | 다음 행동을 맨 위에, 리스트 5개 캡, 군더더기 제거 응답 모드 |
| [anti-slop-frontend](./skills/design/anti-slop-frontend) | design | Available | AI 티 나는 프론트엔드 방지: 브리프 읽기·세 다이얼·LLM 기본값 회피·프리플라이트 (Leonxlnx/taste-skill 적응) |
| [grill-me](./skills/planning/grill-me) | planning | Available | 계획·의사결정·사업 아이디어를 스트레스 테스트하는 집요한 인터뷰 |
| [to-prd](./skills/planning/to-prd) | planning | Available | 현재 대화를 PRD 로 합성 (인터뷰 없음, mattpocock 적응) |
| [to-issues](./skills/planning/to-issues) | planning | Available | 계획/PRD 를 수직 슬라이스 이슈로 분해 (mattpocock 적응) |
| [implement](./skills/planning/implement) | planning | Available | 합의된 PRD/이슈/슬라이스를 커밋된 테스트 코드로 구현 (mattpocock 적응) |
| [codebase-design](./skills/planning/codebase-design) | planning | Available | 깊은 모듈 설계 어휘 (mattpocock 적응) |
| [domain-modeling](./skills/planning/domain-modeling) | planning | Available | 도메인 모델·용어집·ADR 구축·정밀화 (mattpocock 적응) |
| [fe-review](./skills/review/fe-review) | review | Available | 프론트엔드 diff 를 6렌즈(요구사항 추적성·추상화 비용·상태 위치·인터페이스 예측가능성·비동기 UX·숨은 부작용)로 리뷰 |
| [be-review](./skills/review/be-review) | review | Available | Go 백엔드 diff 를 아키텍처 경계·데이터 무결성·에러/보안 규율·Go 관용구로 리뷰 (프로젝트 캐논 어댑터 계약) |
| [js-testing](./skills/testing/js-testing) | testing | Available | JS/TS 코드베이스에서 무엇을 어느 레벨에서 테스트할지 판단 |
| [webapp-testing](./skills/testing/webapp-testing) | testing | Available | Playwright로 로컬 웹앱 테스트 (anthropics 적응) |
| [open-source-reverse-engineering-coach](./skills/learning/open-source-reverse-engineering-coach) | learning | Available | 오픈소스를 인터랙티브 역공학으로 학습 |
| [technical-book-coach](./skills/learning/technical-book-coach) | learning | Available | 기술 서적·문서 코칭 학습 (한글 번역 + 코칭) |
| [git-guardrails](./skills/util/git-guardrails) | util | Available | 위험한 git 명령 차단 hook (Claude Code 전용, mattpocock 적응) |
| [resolving-merge-conflicts](./skills/util/resolving-merge-conflicts) | util | Available | merge/rebase 충돌을 의도 복원으로 해소 (mattpocock 적응) |

## 관련 레포 (Organization)

| 레포 | 공개 | 설명 |
|------|------|------|
| [`zizon`](https://github.com/devjh-jiki/zizon) (이 레포) | 공개 | 인덱스 허브 |
| [`trending-newsletter`](https://github.com/devjh-jiki/trending-newsletter) | 공개 | GitHub trending 한글 뉴스레터 (3관점: 개발/창업/마케팅) |
| [`ai-playground`](https://github.com/devjh-jiki/ai-playground) | 공개 | AI 학습하며 만든 실습 프로젝트 |
| `vault` | 비공개 | 사이드 wiki + 일상/여행 기록 + 학습 노트 |

## 문서 정책

모든 문서는 **영어 원본 + 한국어 `.ko.md` 쌍**으로 관리합니다 (영어가 source of truth).
한쪽을 수정하면 다른 쪽도 같이 수정해야 하며, CI가 쌍 누락을 검사합니다. [CLAUDE.md](./CLAUDE.md) 참고.

## 라이선스

[MIT](./LICENSE) · 서드파티 출처: [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)

# CLAUDE.md

이 레포는 개발 자산의 공개 인덱스 허브입니다. 에이전트는 아래 구조를 따릅니다.

## 디렉토리

- `skills/`: 에이전트 스킬의 단일 원본. 정확히 8개 버킷 폴더로만 분류(23개 스킬, Claude Code 전용):
  - `token/`: 토큰/컨텍스트 소비 절감 (terse-output, context-budget, lazy-code, i-have-adhd)
  - `design/`: 프론트엔드 디자인 품질·취향 (anti-slop-frontend, design-brief)
  - `planning/`: 논의 → 스펙/이슈/도메인 모델 → 실행 (grill-me, to-prd, to-issues, implement, codebase-design, domain-modeling)
  - `review/`: diff 리뷰 (fe-review, be-review)
  - `testing/`: 무엇을·어떻게 테스트할지 (js-testing, webapp-testing)
  - `learning/`: 코드·책 코칭형 학습 (open-source-reverse-engineering-coach, technical-book-coach)
  - `util/`: git 안전장치·충돌 해소 (git-guardrails, resolving-merge-conflicts)
  - `writing/`: 사람이 읽을 글 (article-writing, writing-domain-docs, living-docs-governance)
- `bootstrap/`: 마켓플레이스·플러그인·MCP 서버·hook 을 선언적 manifest(`bootstrap/manifest.json`)로 재현하는 멱등 적용 스크립트. 머신을 새로 세팅하거나 정리할 때 씀.
- `scripts/`: `pnpm validate`/`pnpm test` 가 실행하는 검증·테스트 스크립트.
- `.claude-plugin/`: Claude Code 플러그인(`plugin.json`)·마켓플레이스(`marketplace.json`) 메타데이터.
- `prompts/`: 단발성 복붙 프롬프트 (반복되면 skill 로 승격)
- `learning/ai/`: AI 학습 로드맵·자료·기록
- `snippets/`: 코드/설정 스니펫

이 레포는 **Claude Code 전용**이다. Codex·OpenCode 등 다른 런타임용 어댑터·심볼릭 링크·설정은 없다.

## Skill 규칙 (Anthropic Agent Skills 표준)

모든 스킬은 `skills/<bucket>/<skill-name>/SKILL.md` 형태 하나뿐이며(런타임별 변형 없음), `<bucket>` 은 위 8개 중 하나여야 한다. YAML frontmatter 필수:

```yaml
---
name: skill-name        # 소문자/숫자/하이픈, 64자 이내, "claude"/"anthropic" 금지
description: 무엇을 하는지 + 언제 쓰는지. 1024자 이내. 자동 트리거의 핵심.
---
```

- 공개 스킬은 루트 `README`(한/영)와 `skills/README`(한/영)에 등재한다.
- **`.claude-plugin/plugin.json` 의 `skills` 배열이 23개 스킬 경로를 하나씩 개별 나열한다.** 스킬을 추가·삭제·이동했으면 이 배열도 반드시 같이 고친다. `pnpm validate` 가 디스크(`skills/<bucket>/<name>/`)와 이 배열을 서로 대조해서, 한쪽에만 있는 스킬이 있으면 빌드를 실패시킨다. 잊기 쉬운 단계이자 가장 자주 나오는 실패 원인이니 스킬 작업의 마지막 체크리스트로 삼는다.
- 사용자-호출(user-invoked) 스킬은 `disable-model-invocation: true` 를 두고 사람만 `/명령`으로 실행.
- 모델-호출(model-invoked) 스킬은 작업이 맞으면 에이전트가 자동으로 집어듦.
- 사용자-호출 스킬은 모델-호출 스킬을 부를 수 있으나, 다른 사용자-호출 스킬은 부르지 않는다.

## 버저닝

**버전은 관리하지 않는다. 변경 반영은 항상 재설치로 한다.**

`plugin.json` 의 `version` 을 올리지 않으므로 `claude plugin update` 는 동작하지 않는다. 내용이 바뀌어도 `already at the latest version` 을 반환하고 캐시를 갱신하지 않는다. 실측으로 확인된 동작이다.

| 상황 | 방법 |
|---|---|
| 스킬을 자주 고치는 중 | `./bootstrap/bootstrap.sh --dev`. 로컬 소스로 전환, push 없이 다음 세션에 반영 |
| push 한 변경을 반영 | `claude plugin uninstall zizon@zizon && claude plugin install zizon@zizon` |
| ~~버전 올린 뒤 갱신~~ | ~~`claude plugin update`~~. 이 레포에서는 쓰지 않는다 |

버전을 정본으로 관리하고 싶어지면 `plugin.json` 의 `version` 을 기준으로 삼고 스킬을 고칠 때마다 올려야 한다. 그 전까지 `package.json`(0.1.0) 과 `plugin.json`·`marketplace.json`(0.2.0) 의 불일치는 의도된 방치다. 개인용이라 릴리스가 없고, Changesets 도 `private: true` 라 배포되지 않는다.

- upstream(외부 skills 레포) 동기화는 `.github/workflows/sync-upstream-skills.yml` 가 매주 월요일 `.upstream/` 을 갱신해 **main 에 자동 커밋**한다 (PR 없음). `.upstream/` 은 런타임에서 아무것도 소비하지 않는 참조용 스냅샷이라 승인 없이 갱신해도 안전하다. **다만 `skills/` 는 복사본이 아니라 각색본이므로, upstream 변경을 내 스킬에 반영할지는 항상 별도 판단이다.**

## 한/영 문서 페어 규칙 (중요)

**에이전트가 읽고 실행하는 정본은 `SKILL.md` 하나다.** `SKILL.ko.md` 는 사람이 읽는 번역본이고
Claude 는 로드하지 않는다. `pnpm validate` 도 `.ko.md` 를 보지 않는다.

- 원본: `X.md` · 번역: `X.ko.md`
- **`SKILL.md` 의 `description` 은 영어로 쓴다.** Claude 가 스킬을 고를 때 읽는 값이라
  한국어로 쓰면 영어 프롬프트에 안 걸린다. 한국어 트리거는 따옴표 안에 예시로 넣는다
- **번역은 의무가 아니다.** `.ko.md` 를 만들지 않아도 CI 는 통과한다
- **만들었으면 원본을 따라와야 한다.** 반쯤 낡은 번역은 없는 것보다 나쁘다
- 요점만 옮기고 상세를 원본에 맡기는 것도 정당한 선택이다. **다만 선언한다.**
  `.ko.md` frontmatter 에 `translation: abridged` 를 넣으면 구조 일치 검사에서 빠진다
- **예외. 루트 README**: GitHub 첫 화면 가독성을 위해 루트만 한국어가 메인이다.
  `README.md`(한국어) + `README.en.md`(영어) 쌍이고 둘의 제목 구조는 일치해야 한다

### 검사가 무엇을 보는가

`.github/scripts/check_doc_pairs.py` 가 정본이고 CI 와 로컬이 같은 것을 돌린다.

```sh
python3 .github/scripts/check_doc_pairs.py
```

셋을 본다. `SKILL.md` 의 description 이 영어인가, 짝 없는 `.ko.md` 가 있는가,
번역의 **제목 구조**가 원본과 같은가. 제목 글자는 번역되므로 깊이의 나열만 비교한다.

**옛 판본은 「모든 `X.md` 에 `X.ko.md` 가 있어야 한다」만 봤고 그 검사는 값을 하지 못했다.**
존재만 보고 내용을 안 봐서, 영어에 절을 넣고 한국어를 안 고친 커밋 `b53f162` 를 통과시켰다.
반대로 한국어로 쓴 writing 버킷은 영어 사본이 없다는 이유로 실패시켰다.
잡을 것은 놓치고 안 잡을 것은 잡았으므로 2026-08-28 에 바꿨다.

**검사를 고칠 때는 일부러 깨뜨려 잡히는지 확인한다.** 통과는 검사가 돈다는 증거가 아니다.

## 신뢰도 라벨 (마켓플레이스 운영)

스킬은 검증 단계로 표시한다. 루트 `README` 와 `skills/README` 에 반영:

- **Available**. 직접 테스트·검증 완료. 외부 설치 권장.
- **Review**. 평가 중. 검증되면 Available 로 승격.
- **Private**. 개인 셋업 전용. 마켓플레이스 미포함.

### Review → Available 승격 기준

[skill-creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) 방법론을 차용한다. 스킬 하나당:

1. **트리거 점검.** should-trigger / should-not-trigger 프롬프트(특히 near-miss)로 description 이 적절히 발동하는지 본다. 언더트리거(필요한데 안 뜸)가 가장 흔한 실패.
2. **테스트 2~3개 실행.** 현실적인 프롬프트로 happy path + 그 스킬의 고유 실패 모드(정직성 압박, 계산 정확도, 스코프 규율 등)를 압박한다. 출력이 객관적으로 검증 가능하면(코드·파일·계산) **실제로 실행**해 확인하고, 정성적이면(글·설계·코칭) 산출물을 원칙 충족도로 평가한다. 서브에이전트로 병렬 실행 가능.
3. **정성 평가.** 여러 테스트가 독립적으로 같은 결함을 일으키면 그건 스킬을 고치라는 강한 신호다.
4. **개선.** SKILL.md(정본)와 SKILL.ko.md 를 같은 의미로 함께 고친다. 가장 임팩트 큰 결함부터.
5. **재검증.** 가장 가치 큰 개선이 실제로 작동하는지 핵심 테스트를 다시 돌린다.

**통과 기준**: 고유 실패 모드를 압박한 테스트를 통과하고(또는 개선 후 통과), 출력이 그 스킬의 의도·템플릿·원칙을 충족하며, 치명적 결함이 없다. 남은 개선이 "문구 보강" 수준이면 통과로 본다. 통과 시 `README`(한/영)에서 Review → Available 로 바꾸고, 한/영 쌍·`check-doc-pairs` CI 통과를 확인한 뒤 스킬당 한 커밋으로 남긴다. push 는 사람이 확인 후.

> 이번 라운드에서 거의 모든 스킬의 공통 결함은 **"묻기/리다이렉트 vs 진행 경계"** 와 **"스킬 자체 판단 규칙의 엣지 케이스 미정의"** 였다. 새 스킬을 검증할 때 이 둘을 먼저 점검하면 빠르다.

## 마켓플레이스 배포

- `.claude-plugin/marketplace.json` 으로 Claude Code 마켓플레이스 배포. 단일 플러그인 `zizon` 하나로 23개 스킬 전부를 묶는다. 도메인별로 여러 플러그인으로 쪼개지 않는다.
- 설치: `/plugin marketplace add devjh-jiki/zizon` → `/plugin install zizon@zizon`.
- 새 머신 전체 재현은 `./bootstrap/bootstrap.sh` 하나로 한다. 마켓플레이스·플러그인·전역 MCP·훅까지 한 번에 맞춘다.
- `.claude-plugin/plugin.json` 의 `skills` 배열과 디스크 상태가 어긋나면 마켓플레이스에 새/삭제된 스킬이 반영되지 않거나 설치가 깨진다. "Skill 규칙" 절의 `pnpm validate` 대조를 항상 통과시킨다.

## 검증

스킬·매니페스트·문서를 바꾼 뒤에는:

```sh
pnpm validate && pnpm test
```

`pnpm validate` 는 스킬 frontmatter, 마켓플레이스 경로, `plugin.json` ↔ 디스크 드리프트를 검사한다. `pnpm test` 는 `scripts/*.test.mjs`(node 테스트)와 `scripts/bootstrap-helpers.test.sh`(bootstrap 헬퍼 셸 테스트)를 돌린다. 문서만 바꿨으면 `python3 .github/scripts/check_doc_pairs.py` 도 돌린다. CI 와 같은 파일이다.

# AGENTS.md

이 레포는 재사용 가능한 개발 자산의 공개 인덱스 허브입니다. 변경 사항은 이식 가능해야 하며 기존 한/영 문서 쌍을 유지해야 합니다.

## 레포 구조

- `skills/` — 8개 버킷(`token`, `design`, `planning`, `review`, `testing`, `learning`, `util`, `writing`)으로 분류한 런타임 중립 재사용 스킬의 단일 원본. 단일 Claude Code 플러그인 `zizon` 으로 배포합니다.
- `bootstrap/` — 머신 셋업(마켓플레이스·플러그인·MCP 서버·hook)을 선언적 manifest 로 재현하는 멱등 적용 스크립트.
- `scripts/` — `pnpm validate` / `pnpm test` 가 실행하는 검증·테스트 스크립트(`validate.mjs`, `*.test.mjs`, `bootstrap-helpers.test.sh`).
- `.claude-plugin/` — Claude Code 플러그인(`plugin.json`) 및 마켓플레이스(`marketplace.json`) 메타데이터.
- `prompts/` — 단발성 복붙 프롬프트. 반복되는 워크플로우는 스킬로 승격.
- `learning/ai/` — AI 학습 로드맵, 자료, 기록.
- `snippets/` — 재사용 가능한 코드와 설정 스니펫.

## Skill 규칙

모든 스킬은 `skills/<bucket>/<skill-name>/SKILL.md` 에 두며, `<bucket>` 은 정확히 8개 허용 버킷(`token`, `design`, `planning`, `review`, `testing`, `learning`, `util`, `writing`) 중 하나여야 합니다. 각 스킬은 YAML frontmatter 를 사용합니다.

```yaml
---
name: skill-name
description: 스킬이 하는 일과 활성화되어야 하는 조건.
---
```

- 영어 `SKILL.md`를 단일 원본으로 취급하고 `SKILL.ko.md`를 같은 의미로 동기화합니다.
- `name`에는 소문자, 숫자, 하이픈만 사용합니다.
- 상세 절차는 본문에 두고, 안정적으로 활성화되도록 `description`에 적용 범위를 구체적으로 적습니다.
- `.claude-plugin/plugin.json` 은 모든 스킬 경로를 개별 나열합니다(현재 19개). 스킬을 추가·삭제·이동하면 파일시스템과 이 목록을 함께 갱신해야 합니다 — 둘이 어긋나면 `pnpm validate` 가 빌드를 실패시킵니다.
- 공개 스킬은 **네** 파일에 등록합니다: 루트 README 쌍(`README.md`, `README.en.md`)과 `skills/README` 쌍(`skills/README.md`, `skills/README.ko.md`).

## 한/영 문서 쌍

루트 README를 제외하면 영어가 단일 원본입니다. `.github/workflows/check-doc-pairs.yml` 이 기준입니다 — 레포의 **모든** `*.md` 파일을 검사하며(`README`/`SKILL` 계열만이 아닙니다), 여기엔 `references/` 와 `snippets/` 아래 문서도 포함됩니다:

- `X.md`는 `X.ko.md`와 쌍을 이룹니다.
- 한쪽을 변경하면 다른 쪽도 같은 의미로 갱신합니다.
- 루트 문서는 예외로, `README.md`가 한국어이며 `README.en.md`와 쌍을 이룹니다.
- `CLAUDE.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`, Changeset(`.changeset/*.md`), `docs/superpowers/` 아래 파일, gitignore 된 `.superpowers/` 스크래치 워크스페이스, `*/commands/*.md`, `templates/` 아래 Markdown 은 번역 쌍이 없어도 됩니다. `references/` 와 `snippets/` 는 예외가 **아닙니다** — 거기 있는 문서도 다른 문서와 똑같이 쌍이 필요합니다.

문서를 변경한 뒤 `.github/workflows/check-doc-pairs.yml`과 같은 검사를 실행합니다.

## 작업 규칙

- 작업 트리의 관련 없는 사용자 변경을 보존합니다.
- 편집 전에 관련 스킬, references, 인덱스를 확인합니다.
- 스킬 본문을 중복시키지 말고, 가장 좁고 완전한 변경을 선호합니다.
- 작업에 필요하지 않은 의존성은 추가하지 않습니다.
- 릴리스할 변경에는 Changesets를 사용합니다: `pnpm changeset`.

## 검증

스킬이나 매니페스트를 변경한 뒤 다음을 실행합니다.

```sh
pnpm validate && pnpm test
```

문서를 변경한 경우 레포의 문서 쌍 검사 로직이나 해당 GitHub Actions 워크플로우를 실행합니다.

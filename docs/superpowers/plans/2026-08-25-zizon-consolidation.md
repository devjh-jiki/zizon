# zizon 통합 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 흩어진 에이전트 자산(스킬 35개·전역 MCP 4개·플러그인 6개·중복 훅)을 zizon 레포 하나로 모으고, 새 머신에서 `bootstrap.sh` 한 번으로 재현 가능하게 만든다.

**Architecture:** zizon 은 Claude Code 플러그인 1개를 마켓플레이스로 배포하고(스킬 19개), 플러그인이 담을 수 없는 것(서드파티 플러그인 설치·전역 MCP 정리·settings.json)은 `bootstrap/manifest.json` 이 선언하고 `bootstrap.sh` 가 멱등 적용한다. 전역 MCP 는 0개로 만들고 sentry·figma 는 실제로 쓰는 프로젝트의 `.mcp.json` 으로 내린다.

**Tech Stack:** Node 24 (내장 `node --test`), pnpm 10, bash, `claude` CLI (`plugin`, `plugin marketplace`, `mcp` 서브커맨드), GitHub Actions

**Spec:** `docs/superpowers/specs/2026-08-25-zizon-design.md`

## Global Constraints

- Node ≥ 20 (검증 환경 v24.16.0), pnpm 10.33.2
- **의존성 추가 금지.** 테스트는 Node 내장 `node --test` 로만 작성한다 (AGENTS.md 「Do not add dependencies unless the task requires them」)
- **한/영 문서 쌍 필수.** `X.md` 는 `X.ko.md` 와 쌍. 면제: `*CLAUDE.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`, `./.changeset/*.md`, `*/commands/*.md`, `./templates/**`, `./README.md`, `./README.en.md`, `*.en.md`, `./docs/superpowers/*`
- 루트 README 만 예외: `README.md` 가 한국어, `README.en.md` 가 영어
- 스킬 frontmatter 는 `name`(소문자·숫자·하이픈만) + `description` 필수. `name` 은 디렉토리명과 일치해야 한다
- 영어 `SKILL.md` 가 source of truth, `SKILL.ko.md` 는 의미 동기화
- **공개 레포다.** wallcheon private 코드·동료 코멘트가 어떤 형태로도 유입되면 안 된다. few-shot 예시는 본인 소유 저장소(jjan `apps/web`, kalyx, jihoon-blog)에서만 발췌한다
- 시크릿은 `${VAR}` 로 참조하고 실제 값은 `~/.config/zizon/env` 에 둔다. 레포에는 `env.example` 만 커밋한다
- 커밋 메시지는 한국어. release-worthy 변경은 `pnpm changeset` 사용
- 작업 브랜치: `design/zizon-consolidation` (이미 생성됨, 스펙 커밋 2개 존재)

## File Structure

| 경로 | 책임 |
|---|---|
| `scripts/validate.mjs` | 스킬 frontmatter·디렉토리명 일치·마켓플레이스 경로 실재 검사. 이후 모든 구조 변경의 안전망 |
| `scripts/validate.test.mjs` | 위 검증기의 단위 테스트 (`node --test`) |
| `.claude-plugin/plugin.json` | 플러그인 메타데이터 (신규) |
| `.claude-plugin/marketplace.json` | 5묶음 → 1개 플러그인으로 재작성 |
| `skills/<bucket>/<skill>/SKILL.md` | 스킬 본문. 버킷 7개: token, design, planning, review, testing, learning, util |
| `bootstrap/manifest.json` | 원하는 상태 선언 (마켓플레이스·플러그인·MCP·프로젝트 스코프) |
| `bootstrap/bootstrap.sh` | manifest 를 읽어 멱등 적용. `--dry-run`, `--dev` 지원 |
| `bootstrap/env.example` | 시크릿 템플릿 |
| `.github/workflows/sync-upstream-skills.yml` | upstream 목록에 `ayghri/i-have-adhd` 추가 |

---

### Task 1: 검증 스크립트 — 이후 모든 변경의 안전망

구조를 바꾸기 전에 검증기를 먼저 만든다. 스킬을 지우고 옮기는 동안 깨진 상태를 즉시 잡아준다.

**Files:**
- Create: `scripts/validate.mjs`
- Create: `scripts/validate.test.mjs`
- Modify: `package.json` (scripts 에 `validate`, `test` 추가)

**Interfaces:**
- Produces: `validateSkills(rootDir) -> {errors: string[]}` — 에러 배열이 비면 통과. Task 2·3·4·5 가 이 함수를 호출해 검증한다.

- [ ] **Step 1: 실패하는 테스트 작성**

`scripts/validate.test.mjs`:

```javascript
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { validateSkills } from './validate.mjs';

async function fixture(skills) {
  const root = await mkdtemp(join(tmpdir(), 'zizon-'));
  for (const [path, body] of Object.entries(skills)) {
    const dir = join(root, path);
    await mkdir(dir, { recursive: true });
    await writeFile(join(dir, 'SKILL.md'), body);
  }
  return root;
}

test('frontmatter 가 온전하면 에러가 없다', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\ndescription: Be terse.\n---\n본문',
  });
  const { errors } = await validateSkills(root);
  assert.deepEqual(errors, []);
});

test('name 이 디렉토리명과 다르면 에러', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: wrong-name\ndescription: Be terse.\n---\n본문',
  });
  const { errors } = await validateSkills(root);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /terse-output/);
});

test('description 이 없으면 에러', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\n---\n본문',
  });
  const { errors } = await validateSkills(root);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /description/);
});

test('허용되지 않은 버킷은 에러', async () => {
  const root = await fixture({
    'skills/nonsense/foo': '---\nname: foo\ndescription: X.\n---\n본문',
  });
  const { errors } = await validateSkills(root);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /nonsense/);
});
```

- [ ] **Step 2: 테스트를 실행해 실패를 확인**

Run: `node --test scripts/validate.test.mjs`
Expected: FAIL — `Cannot find module './validate.mjs'`

- [ ] **Step 3: 최소 구현 작성**

`scripts/validate.mjs`:

```javascript
import { readdir, readFile, stat } from 'node:fs/promises';
import { join } from 'node:path';

export const BUCKETS = ['token', 'design', 'planning', 'review', 'testing', 'learning', 'util'];

function parseFrontmatter(text) {
  const m = text.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return null;
  const out = {};
  for (const line of m[1].split('\n')) {
    const kv = line.match(/^([a-zA-Z_-]+):\s*(.*)$/);
    if (kv) out[kv[1]] = kv[2].trim();
  }
  return out;
}

async function listDirs(path) {
  try {
    const entries = await readdir(path, { withFileTypes: true });
    return entries.filter((e) => e.isDirectory()).map((e) => e.name);
  } catch {
    return [];
  }
}

export async function validateSkills(root) {
  const errors = [];
  const skillsRoot = join(root, 'skills');
  for (const bucket of await listDirs(skillsRoot)) {
    if (!BUCKETS.includes(bucket)) {
      errors.push(`허용되지 않은 버킷: skills/${bucket} (허용: ${BUCKETS.join(', ')})`);
      continue;
    }
    for (const name of await listDirs(join(skillsRoot, bucket))) {
      const file = join(skillsRoot, bucket, name, 'SKILL.md');
      try {
        await stat(file);
      } catch {
        errors.push(`SKILL.md 없음: skills/${bucket}/${name}`);
        continue;
      }
      const fm = parseFrontmatter(await readFile(file, 'utf8'));
      if (!fm) {
        errors.push(`frontmatter 없음: skills/${bucket}/${name}/SKILL.md`);
        continue;
      }
      if (!fm.description) errors.push(`description 없음: skills/${bucket}/${name}/SKILL.md`);
      if (!fm.name) errors.push(`name 없음: skills/${bucket}/${name}/SKILL.md`);
      else if (fm.name !== name) errors.push(`name 불일치: skills/${bucket}/${name} 의 name 이 "${fm.name}"`);
      else if (!/^[a-z0-9-]+$/.test(fm.name)) errors.push(`name 형식 위반: ${fm.name} (소문자·숫자·하이픈만)`);
    }
  }
  return { errors };
}
```

- [ ] **Step 4: 테스트를 실행해 통과를 확인**

Run: `node --test scripts/validate.test.mjs`
Expected: PASS — 4 tests

- [ ] **Step 5: CLI 진입점 추가**

`scripts/validate.mjs` 끝에 덧붙인다:

```javascript
if (import.meta.url === `file://${process.argv[1]}`) {
  const { errors } = await validateSkills(process.cwd());
  if (errors.length) {
    for (const e of errors) console.error(`✗ ${e}`);
    process.exit(1);
  }
  console.log('✓ 스킬 검증 통과');
}
```

`package.json` 의 `scripts` 에 추가:

```json
"validate": "node scripts/validate.mjs",
"test": "node --test scripts/*.test.mjs"
```

- [ ] **Step 6: 커밋**

```bash
git add scripts/validate.mjs scripts/validate.test.mjs package.json
git commit -m "test: 스킬 구조 검증기 추가 — 이후 재편의 안전망"
```

---

### Task 2: 스킬 19개 제거

**Files:**
- Delete: `skills/business/` (3개), 아래 목록의 engineering·productivity·misc 스킬

**Interfaces:**
- Consumes: Task 1 의 `pnpm validate`
- Produces: 남은 스킬 16개 (Task 3 이 재배치한다)

- [ ] **Step 1: 제거 전 개수를 기록**

Run: `find skills runtimes/claude-code/skills -name SKILL.md | wc -l`
Expected: `35`

- [ ] **Step 2: superpowers 중복 5개 삭제**

```bash
git rm -r skills/engineering/verification-before-completion \
          skills/engineering/tdd \
          skills/engineering/diagnosing-bugs \
          skills/productivity/handoff \
          skills/productivity/writing-great-skills
```

- [ ] **Step 3: 분류 밖·내부 중복 14개 삭제**

```bash
git rm -r skills/business \
          skills/engineering/eval-harness \
          skills/engineering/improve-codebase-architecture \
          skills/engineering/prototype \
          skills/engineering/iterative-retrieval \
          skills/engineering/grill-with-docs \
          skills/engineering/design-system \
          skills/productivity/council \
          skills/productivity/recency-research \
          skills/productivity/document-with-research \
          skills/productivity/write-blog-post \
          skills/misc/setup-pre-commit
```

`skills/business` 는 디렉토리째 3개(biz-opportunity-scout, marketing-copy, product-spec-builder)를 지운다.

- [ ] **Step 4: 개수 확인**

Run: `find skills runtimes/claude-code/skills -name SKILL.md | wc -l`
Expected: `16`

남아야 할 16개: `anti-slop-frontend` `codebase-design` `domain-modeling` `go-backend-review` `implement` `lazy-code` `resolving-merge-conflicts` `to-issues` `to-prd` `webapp-testing` `open-source-reverse-engineering-coach` `technical-book-coach` `context-budget` `grill-me` `terse-output` `git-guardrails`

- [ ] **Step 5: 커밋**

```bash
git add -A skills
git commit -m "refactor(skills): 중복·분류 밖 스킬 19개 제거 (35 → 16)

superpowers 중복 5개: verification-before-completion(이름 동일),
handoff(agentmemory:handoff 충돌), tdd, diagnosing-bugs,
writing-great-skills — 후자 셋은 superpowers 쪽이 4~7배 상세.

분류 밖·내부 중복 14개. design-system 은 astryx.atmeta.com 을 9군데
하드코딩하고 있고 해당 MCP 가 사라져 현재 동작하지 않음."
```

---

### Task 3: 스킬 16개를 7버킷으로 재배치하고 죽은 디렉토리 삭제

**Files:**
- Move: `skills/{engineering,productivity,learning,misc}/*` → `skills/{token,design,planning,review,testing,learning,util}/*`
- Move: `runtimes/claude-code/skills/git-guardrails` → `skills/util/git-guardrails`
- Delete: `.agents/`, `runtimes/`, `mcp/`

**Interfaces:**
- Consumes: Task 2 의 결과 16개
- Produces: `skills/<bucket>/<name>/SKILL.md` 구조. Task 4 의 marketplace.json 이 이 경로를 참조한다.

- [ ] **Step 1: 버킷 생성 후 이동**

```bash
mkdir -p skills/{token,design,planning,review,testing,util}

git mv skills/productivity/terse-output      skills/token/terse-output
git mv skills/productivity/context-budget    skills/token/context-budget
git mv skills/engineering/lazy-code          skills/token/lazy-code

git mv skills/engineering/anti-slop-frontend skills/design/anti-slop-frontend

git mv skills/productivity/grill-me          skills/planning/grill-me
git mv skills/engineering/to-prd             skills/planning/to-prd
git mv skills/engineering/to-issues          skills/planning/to-issues
git mv skills/engineering/implement          skills/planning/implement
git mv skills/engineering/codebase-design    skills/planning/codebase-design
git mv skills/engineering/domain-modeling    skills/planning/domain-modeling

git mv skills/engineering/go-backend-review  skills/review/be-review

git mv skills/engineering/webapp-testing     skills/testing/webapp-testing

git mv skills/engineering/resolving-merge-conflicts skills/util/resolving-merge-conflicts
git mv runtimes/claude-code/skills/git-guardrails   skills/util/git-guardrails
```

`learning/` 의 2개는 이미 올바른 버킷에 있으므로 이동하지 않는다.

- [ ] **Step 2: `be-review` 의 frontmatter name 을 디렉토리명에 맞춤**

`skills/review/be-review/SKILL.md` 의 frontmatter 에서 `name: go-backend-review` 를 `name: be-review` 로 바꾼다. Task 1 의 검증기가 name↔디렉토리명 일치를 강제하므로 이 단계를 빠뜨리면 검증이 실패한다.

- [ ] **Step 3: 빈 디렉토리와 죽은 런타임 자산 삭제**

```bash
git rm -r .agents runtimes mcp
rmdir skills/engineering skills/productivity skills/misc 2>/dev/null || true
```

`.agents/skills` 의 심볼릭 링크 34개와 `runtimes/{codex,cursor,vscode,opencode}` 는 Claude Code 전용 결정(D2)으로, `mcp/` 는 전역 MCP 0개 결정으로 전부 무의미해진다.

- [ ] **Step 4: 검증 실행**

Run: `pnpm validate && find skills -name SKILL.md | wc -l`
Expected: `✓ 스킬 검증 통과` 그리고 `16`

- [ ] **Step 5: 커밋**

```bash
git add -A
git commit -m "refactor(skills): 6분류+util 버킷 구조로 재배치

engineering/productivity/misc 를 해체하고 token·design·planning·
review·testing·learning·util 로 재배치. go-backend-review 를
review/be-review 로 개명.

Claude Code 전용 결정에 따라 .agents/(심볼릭 링크 34개),
runtimes/(codex·cursor·vscode·opencode), mcp/ 삭제."
```

---

### Task 4: 플러그인 매니페스트 — 5묶음을 1개로

**Files:**
- Create: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (전면 재작성)
- Modify: `scripts/validate.mjs` (마켓플레이스 정합성 검사 추가)
- Modify: `scripts/validate.test.mjs` (테스트 추가)

**Interfaces:**
- Consumes: Task 3 의 `skills/<bucket>/<name>/` 경로
- Produces: `zizon@zizon` 플러그인 식별자. Task 9 의 manifest.json 이 이 이름으로 설치한다.

- [ ] **Step 1: 마켓플레이스 검증 테스트를 먼저 작성**

`scripts/validate.test.mjs` 에 추가:

```javascript
import { validateMarketplace } from './validate.mjs';

test('marketplace 의 skills 경로가 실재하면 통과', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\ndescription: Be terse.\n---\n본문',
  });
  await writeFile(join(root, 'marketplace.json'), JSON.stringify({
    plugins: [{ name: 'zizon', skills: ['./skills/token/terse-output'] }],
  }));
  const { errors } = await validateMarketplace(root, join(root, 'marketplace.json'));
  assert.deepEqual(errors, []);
});

test('디렉토리 형식 ./skills/ 은 하위에 스킬이 있으면 통과', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\ndescription: Be terse.\n---\n본문',
  });
  await writeFile(join(root, 'marketplace.json'), JSON.stringify({
    plugins: [{ name: 'zizon', skills: ['./skills/'] }],
  }));
  const { errors } = await validateMarketplace(root, join(root, 'marketplace.json'));
  assert.deepEqual(errors, []);
});

test('디렉토리 형식인데 하위에 스킬이 없으면 에러', async () => {
  const root = await fixture({});
  await writeFile(join(root, 'marketplace.json'), JSON.stringify({
    plugins: [{ name: 'zizon', skills: ['./skills/'] }],
  }));
  const { errors } = await validateMarketplace(root, join(root, 'marketplace.json'));
  assert.equal(errors.length, 1);
  assert.match(errors[0], /스킬이 없음/);
});

test('marketplace 가 없는 스킬을 가리키면 에러', async () => {
  const root = await fixture({});
  await writeFile(join(root, 'marketplace.json'), JSON.stringify({
    plugins: [{ name: 'zizon', skills: ['./skills/token/ghost'] }],
  }));
  const { errors } = await validateMarketplace(root, join(root, 'marketplace.json'));
  assert.equal(errors.length, 1);
  assert.match(errors[0], /ghost/);
});
```

- [ ] **Step 2: 테스트를 실행해 실패를 확인**

Run: `node --test scripts/validate.test.mjs`
Expected: FAIL — `validateMarketplace is not a function`

- [ ] **Step 3: 검증 함수 구현**

`scripts/validate.mjs` 에 추가:

```javascript
export async function validateMarketplace(root, manifestPath) {
  const errors = [];
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  for (const plugin of manifest.plugins ?? []) {
    for (const rel of plugin.skills ?? []) {
      if (rel.endsWith('/')) {
        // 디렉토리 형식('./skills/') — 하위에 SKILL.md 가 하나라도 있어야 한다
        const dir = join(root, rel);
        const found = [];
        for (const bucket of await listDirs(dir)) {
          for (const name of await listDirs(join(dir, bucket))) {
            try { await stat(join(dir, bucket, name, 'SKILL.md')); found.push(name); } catch {}
          }
        }
        if (!found.length) errors.push(`marketplace 디렉토리에 스킬이 없음: ${rel} (${plugin.name})`);
        continue;
      }
      try {
        await stat(join(root, rel, 'SKILL.md'));
      } catch {
        errors.push(`marketplace 가 없는 스킬을 가리킴: ${rel} (${plugin.name})`);
      }
    }
  }
  return { errors };
}
```

CLI 진입점도 확장한다:

```javascript
if (import.meta.url === `file://${process.argv[1]}`) {
  const root = process.cwd();
  const a = await validateSkills(root);
  const b = await validateMarketplace(root, join(root, '.claude-plugin/marketplace.json'));
  const errors = [...a.errors, ...b.errors];
  if (errors.length) {
    for (const e of errors) console.error(`✗ ${e}`);
    process.exit(1);
  }
  console.log('✓ 스킬·마켓플레이스 검증 통과');
}
```

- [ ] **Step 4: 테스트를 실행해 통과를 확인**

Run: `node --test scripts/validate.test.mjs`
Expected: PASS — 8 tests

- [ ] **Step 5: plugin.json 작성**

`.claude-plugin/plugin.json`:

```json
{
  "name": "zizon",
  "version": "0.2.0",
  "description": "개인 에이전트 자산 — 토큰절약·디자인·계획·리뷰·테스트·학습 스킬 19개",
  "author": { "name": "devjh-jiki", "url": "https://github.com/devjh-jiki" },
  "license": "MIT",
  "homepage": "https://github.com/devjh-jiki/zizon",
  "repository": "https://github.com/devjh-jiki/zizon",
  "skills": ["./skills/"]
}
```

- [ ] **Step 6: marketplace.json 재작성**

`.claude-plugin/marketplace.json` 전체를 다음으로 교체한다. 기존 5묶음(writing-skills, engineering-skills, learning-skills, business-skills, misc-skills)은 사라진다.

```json
{
  "name": "zizon",
  "owner": { "name": "devjh-jiki", "url": "https://github.com/devjh-jiki" },
  "metadata": { "description": "zizon — 개인 에이전트 자산 단일 소스", "version": "0.2.0" },
  "plugins": [
    {
      "name": "zizon",
      "source": "./",
      "version": "0.2.0",
      "description": "토큰절약·디자인·계획·리뷰·테스트·학습 스킬 19개. Claude Code 전용.",
      "author": { "name": "devjh-jiki", "url": "https://github.com/devjh-jiki" },
      "strict": false,
      "skills": ["./skills/"]
    }
  ]
}
```

`skills` 를 개별 경로 나열이 아니라 `./skills/` 디렉토리 하나로 두면 Task 6~8 에서 스킬을 추가할 때 매니페스트를 고치지 않아도 된다.

- [ ] **Step 7: 전체 검증 — 자체 검증기 + Claude Code 공식 검증기**

Run: `claude plugin validate .`
Expected: 매니페스트 유효. 자체 검증기가 못 잡는 스키마 오류를 여기서 잡는다.

Run: `pnpm validate && pnpm test`
Expected: `✓ 스킬·마켓플레이스 검증 통과`, 8 tests pass

- [ ] **Step 8: 커밋**

```bash
git add .claude-plugin scripts package.json
git commit -m "feat(plugin): 마켓플레이스를 플러그인 1개 구조로 재작성

5묶음(writing/engineering/learning/business/misc)을 zizon 하나로 통합.
skills 를 ./skills/ 디렉토리로 선언해 스킬 추가 시 매니페스트 수정이
필요 없게 함.

검증기에 마켓플레이스 경로 실재 검사 추가."
```

---

### Task 5: i-have-adhd 동기화

**Files:**
- Create: `skills/token/i-have-adhd/SKILL.md`, `skills/token/i-have-adhd/SKILL.ko.md`
- Modify: `THIRD_PARTY_NOTICES.md`
- Modify: `.github/workflows/sync-upstream-skills.yml`

**Interfaces:**
- Produces: `skills/token/i-have-adhd` — Task 4 의 `./skills/` 선언이 자동으로 포함한다

- [ ] **Step 1: upstream 등록**

`.github/workflows/sync-upstream-skills.yml` 의 `upstream:` 배열 끝(현재 obra/superpowers 다음)에 추가한다:

```yaml
          - owner: ayghri
            repo: i-have-adhd
            ref: main
            path: skills
```

- [ ] **Step 2: 스킬 본문 작성**

`skills/token/i-have-adhd/SKILL.md` 를 작성한다. 원문(MIT)의 10개 출력 규칙을 옮기되, frontmatter 는 zizon 규약에 맞춘다:

```markdown
---
name: i-have-adhd
description: Use when responses bury the actionable step under explanation — reformats output to lead with the next action, number multi-step work, and cut preamble and closing pleasantries.
---
```

본문에는 원문의 규칙을 옮긴다: 즉시 실행할 행동을 첫 줄에 둘 것, 다단계 작업은 번호를 매길 것, 목록은 5개를 넘기지 말 것, 서두와 맺음 인사를 없앨 것, 다음에 무엇을 요청해야 하는지 구체적으로 남길 것.

`SKILL.ko.md` 는 같은 내용의 한국어판으로 작성한다 (한/영 쌍 필수).

- [ ] **Step 3: 라이선스 고지**

`THIRD_PARTY_NOTICES.md` 에 항목을 추가한다:

```markdown
### skills/token/i-have-adhd

- 출처: https://github.com/ayghri/i-have-adhd
- 라이선스: MIT
- 저작권: Copyright (c) 2026 Ayoub Ghriss
```

같은 파일에 `skills/testing/js-testing` 항목도 미리 추가한다 (Task 8 에서 작성):

```markdown
### skills/testing/js-testing

- 출처: https://github.com/goldbergyoni/javascript-testing-best-practices
- 라이선스: MIT
```

- [ ] **Step 4: 검증**

Run: `pnpm validate`
Expected: `✓ 스킬·마켓플레이스 검증 통과` (스킬 17개)

- [ ] **Step 5: 한/영 쌍 검사**

Run: `bash -c 'cd "$(git rev-parse --show-toplevel)" && find skills -name "*.md" -not -name "*.ko.md" | while read f; do [ -f "${f%.md}.ko.md" ] || echo "쌍 없음: $f"; done'`
Expected: 출력 없음

- [ ] **Step 6: 커밋**

```bash
git add skills/token/i-have-adhd THIRD_PARTY_NOTICES.md .github/workflows/sync-upstream-skills.yml
git commit -m "feat(skills): i-have-adhd 동기화 (token 버킷)

ayghri/i-have-adhd (MIT) 의 출력 형식 10규칙. upstream 자동 동기화
목록에 등록하고 THIRD_PARTY_NOTICES 에 고지."
```

---

### Task 6: fe-review 스킬 작성

**Files:**
- Create: `skills/review/fe-review/SKILL.md`, `skills/review/fe-review/SKILL.ko.md`
- Create: `skills/review/fe-review/references/lenses.md`, `references/lenses.ko.md`

**Interfaces:**
- Produces: `fe-review` 스킬. `be-review` 와 같은 출력 규약(`docs/reviews/YYYY-MM-DD-<주제>.md`)을 따른다.

**제약 (Global Constraints 재확인):** wallcheon private 코드·동료 코멘트를 어떤 형태로도 참조하지 않는다. few-shot 예시는 jjan `apps/web`, kalyx, jihoon-blog 에서만 발췌한다. 기존 `fe-review-bot` 레포의 `personas/`, `agents/`, `corpus/` 는 열지 않는다.

- [ ] **Step 1: SKILL.md frontmatter 와 골격 작성**

```markdown
---
name: fe-review
description: Use when reviewing frontend changes (React/Next.js components, hooks, state, async UI) — reviews a diff through six explicit lenses and writes the result to docs/reviews/. Invoke by name; not automatic.
---
```

본문 구성:
1. **입력** — 기본 대상은 `git diff main...HEAD`. 파일·커밋 범위·PR 지정 가능
2. **6개 렌즈를 순서대로 적용** (아래 Step 2)
3. **출력** — 인라인 지적 + `<repo>/docs/reviews/YYYY-MM-DD-<주제>.md` (상단에 일시·대상 범위 기록)
4. **하지 않는 것** — 스타일/포매팅 지적(린터의 몫), 취향 차이를 결함으로 포장하기, 근거 없는 추측

- [ ] **Step 2: `references/lenses.md` 에 렌즈 6축 작성**

각 렌즈마다 ① 묻는 질문 ② 체크리스트 3~5개 ③ before/after 예시 1개를 쓴다.

예시는 다음 경로에서만 발췌한다 (전부 본인 소유):

- `~/Desktop/jihoon/jjan/apps/web/` — Next.js PWA. 상태의 위치·비동기 UX 예시에 적합
- `~/Desktop/kalyx/src/` — 라이브러리. 인터페이스 예측가능성·추상화 비용 예시에 적합
- `~/Desktop/jihoon-blog/` — 요구사항 추적성·숨은 동작 예시에 적합

`fe-review-bot` 레포(`~/Desktop/jihoon/dev-jihoon/fe-review-bot`)의 `personas/`, `agents/`, `corpus/` 는 **열지 않는다.** 읽는 순간 wallcheon 자료가 컨텍스트에 유입된다.

| 렌즈 | 묻는 것 |
|---|---|
| 요구사항 추적성 | 이 코드가 무슨 요구사항을 만족시키는지 읽히나 |
| 추상화 비용 | 이 추상화가 벌어들이는 것보다 비싸지 않나 |
| 상태의 위치 | 전역·컨텍스트로 올라간 상태가 정말 그 자리여야 하나 |
| 인터페이스 예측가능성 | 이름과 시그니처가 실제 동작과 일치하나 |
| 비동기 UX | 로딩·에러·빈 상태가 설계되었나 |
| 숨은 동작 | 호출자가 모르는 부수효과가 있나 |

- [ ] **Step 3: 한국어판 작성**

`SKILL.ko.md`, `references/lenses.ko.md` 를 의미 동기화해 작성한다.

- [ ] **Step 4: 검증**

Run: `pnpm validate`
Expected: `✓ 스킬·마켓플레이스 검증 통과` (스킬 18개)

- [ ] **Step 5: 출처 오염 검사**

Run: `grep -ril "wallcheon\|hobin\|seung-wan\|seungwan" skills/ || echo "오염 없음"`
Expected: `오염 없음`

- [ ] **Step 6: 커밋**

```bash
git add skills/review/fe-review
git commit -m "feat(skills): fe-review — 관점 6축 프론트엔드 리뷰

인물 재현 대신 렌즈를 명시적 축으로 일반화. 요구사항 추적성·추상화
비용·상태의 위치·인터페이스 예측가능성·비동기 UX·숨은 동작.

few-shot 예시는 본인 소유 저장소에서만 발췌 — wallcheon 자료 유입 없음."
```

---

### Task 7: be-review 캐논 슬롯 활성화 + jjan 캐논 작성

**Files:**
- Modify: `skills/review/be-review/SKILL.md`, `SKILL.ko.md`
- Create (다른 레포): `~/Desktop/jihoon/jjan/docs/review-canon.md`

**Interfaces:**
- Consumes: Task 3 에서 개명된 `skills/review/be-review`
- Produces: `<repo>/docs/review-canon.md` 규약 — 프로젝트별 리뷰 규칙 파일 경로

- [ ] **Step 1: 캐논 슬롯 절차를 SKILL.md 에 명시**

기존의 "project-canon adapter slot" 서술을 실제 절차로 바꾼다:

```markdown
## 프로젝트 캐논

리뷰 시작 전에 `<repo>/docs/review-canon.md` 가 있는지 확인한다.

- 있으면: 읽고, 그 규칙을 이 스킬의 일반 원칙보다 **우선** 적용한다. 충돌하면 캐논이 이긴다.
- 없으면: 일반 원칙만 적용하고, 리뷰 말미에 캐논 파일을 만들 것을 제안한다.

캐논은 프로젝트 저장소에 있고 이 스킬에는 들어오지 않는다 — private 레포의 규칙이 공개 스킬로 새지 않게 하기 위해서다.
```

- [ ] **Step 2: 한국어판 동기화**

`SKILL.ko.md` 에 같은 섹션을 반영한다.

- [ ] **Step 3: 검증 후 zizon 쪽 커밋**

Run: `pnpm validate`
Expected: 통과

```bash
git add skills/review/be-review
git commit -m "feat(skills): be-review 프로젝트 캐논 슬롯 구현

<repo>/docs/review-canon.md 가 있으면 읽어 일반 원칙보다 우선 적용.
캐논은 프로젝트 저장소에 남아 private 규칙이 공개 스킬로 새지 않는다."
```

- [ ] **Step 4: jjan 캐논 초안 작성**

jjan 레포(`~/Desktop/jihoon/jjan`)에서 기존 리뷰 문서 5개를 읽어 반복 지적 패턴을 추출한다:

Run: `ls ~/Desktop/jihoon/jjan/docs/reviews/`
대상: `2026-08-09-p1-1-monorepo-be.md`, `2026-08-10-p1-4-openapi-be.md`, `2026-08-14-commute-domain-be.md`, `2026-08-14-commute-http-be.md`

이 문서들에서 두 번 이상 반복된 지적만 골라 `~/Desktop/jihoon/jjan/docs/review-canon.md` 로 정리한다. 한 번만 나온 지적은 캐논이 아니라 그 PR 의 사정이므로 넣지 않는다.

- [ ] **Step 5: jjan 쪽 커밋**

```bash
cd ~/Desktop/jihoon/jjan
git checkout -b docs/review-canon
git add docs/review-canon.md
git commit -m "docs: 백엔드 리뷰 캐논 정리

기존 docs/reviews/*-be.md 4건에서 두 번 이상 반복된 지적을 추출.
zizon 의 be-review 스킬이 이 파일을 읽어 일반 원칙보다 우선 적용한다."
```

---

### Task 8: js-testing 스킬 작성

**Files:**
- Create: `skills/testing/js-testing/SKILL.md`, `SKILL.ko.md`

**Interfaces:**
- Produces: `js-testing`. `webapp-testing`(Playwright 구동)과 `superpowers:test-driven-development`(TDD 루프)와 역할이 겹치지 않아야 한다.

- [ ] **Step 1: 역할 경계를 frontmatter 에 못박기**

```markdown
---
name: js-testing
description: Use when deciding what to test and at which level in a JS/TS codebase — test level selection, naming, data setup, and what not to assert. For driving a browser use webapp-testing; for the red-green-refactor loop use superpowers:test-driven-development.
---
```

description 에 다른 두 스킬을 명시적으로 가리켜, 세 스킬이 서로를 먹지 않게 한다.

- [ ] **Step 2: 판단이 갈리는 항목만 증류**

`goldbergyoni/javascript-testing-best-practices`(MIT) 50+ 항목 중 **실제로 판단이 갈리는 것만** 옮긴다. 전량 이식은 원문 링크와 가치가 같으므로 금지한다. 최소한 다음을 다룬다:

1. 테스트 층위 선택 — 무엇을 유닛으로, 무엇을 통합으로, 무엇을 E2E 로
2. 테스트 이름 3부분 구조 — 무엇을 / 어떤 상황에서 / 무엇을 기대하는가
3. 블랙박스 원칙 — 공개 동작만 검증하고 내부 구현에 묶지 않기
4. 테스트 데이터 — 공유 픽스처 대신 테스트마다 팩토리로 생성
5. 스냅샷의 함정 — 언제 쓰고 언제 쓰지 말아야 하나
6. 커버리지의 함정 — 숫자가 말하지 않는 것

각 항목은 ① 원칙 한 줄 ② 왜 갈리는지 ③ 판단 기준으로 쓴다.

- [ ] **Step 3: 한국어판 작성**

`SKILL.ko.md` 를 의미 동기화해 작성한다. 원문에 한국어판(`readme.kr.md`)이 있으므로 용어를 맞춘다.

- [ ] **Step 4: 검증**

Run: `pnpm validate && pnpm test`
Expected: 통과, 스킬 19개

Run: `find skills -name SKILL.md | wc -l`
Expected: `19`

Run (THIRD_PARTY_NOTICES 의 모든 인용 경로가 실재하는지 — Task 5 가 `js-testing` 을 선참조해 두었다):
```bash
grep -o '`skills/[a-z-]*/[a-z0-9-]*`' THIRD_PARTY_NOTICES.md | tr -d '`' | sort -u   | while read p; do [ -f "$p/SKILL.md" ] || echo "죽은 경로: $p"; done
```
Expected: 출력 없음

- [ ] **Step 5: 커밋**

```bash
git add skills/testing/js-testing
git commit -m "feat(skills): js-testing — 무엇을 어느 층위에서 테스트할지 판단

goldbergyoni/javascript-testing-best-practices (MIT) 에서 판단이
갈리는 항목만 증류. 전량 이식은 원문 링크와 가치가 같아 금지.

역할 경계: js-testing 은 판단, webapp-testing 은 Playwright 구동,
superpowers:test-driven-development 는 TDD 루프."
```

---

### Task 9: bootstrap 작성

**Files:**
- Create: `bootstrap/manifest.json`, `bootstrap/bootstrap.sh`, `bootstrap/env.example`
- Create: `scripts/bootstrap.test.mjs`

**Interfaces:**
- Consumes: Task 4 의 `zizon@zizon` 식별자
- Produces: `bootstrap.sh [--dry-run] [--dev]` — Task 11 이 실제로 실행한다

- [ ] **Step 1: manifest.json 작성**

```json
{
  "marketplaces": {
    "keep": [
      { "name": "claude-plugins-official", "source": "anthropics/claude-plugins-official" },
      { "name": "agentmemory", "source": "rohitg00/agentmemory" },
      { "name": "zizon", "source": "devjh-jiki/zizon" }
    ],
    "remove": ["understand-anything", "karpathy-skills", "claude-video", "gitkraken"]
  },
  "plugins": {
    "keep": ["superpowers@claude-plugins-official", "agentmemory@agentmemory", "zizon@zizon"],
    "remove": [
      "understand-anything@understand-anything",
      "andrej-karpathy-skills@karpathy-skills",
      "watch@claude-video",
      "gitkraken-hooks@gitkraken"
    ]
  },
  "mcpServers": { "userScope": { "remove": ["serena", "figma", "sentry"] } },
  "projectScoped": {
    "~/Desktop/jihoon-blog": { "sentry": { "type": "http", "url": "https://mcp.sentry.dev/mcp" } },
    "~/Desktop/kalyx": { "sentry": { "type": "http", "url": "https://mcp.sentry.dev/mcp" } },
    "~/Desktop/jihoon/mutal": {
      "figma": { "command": "npx", "args": ["-y", "figma-developer-mcp", "--stdio"], "env": { "FIGMA_API_KEY": "${FIGMA_API_KEY}" } }
    }
  },
  "settings": { "removeHooks": { "reason": "agentmemory 플러그인이 ${CLAUDE_PLUGIN_ROOT} 로 이미 등록함 — settings.json 사본은 이중 실행", "matchCommand": "agentmemory" } }
}
```

- [ ] **Step 2: 멱등성 테스트를 먼저 작성**

`scripts/bootstrap.test.mjs`:

```javascript
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

test('manifest 는 유효한 JSON 이고 필수 키를 갖는다', async () => {
  const m = JSON.parse(await readFile('bootstrap/manifest.json', 'utf8'));
  for (const key of ['marketplaces', 'plugins', 'mcpServers', 'projectScoped', 'settings']) {
    assert.ok(key in m, `manifest 에 ${key} 가 없다`);
  }
});

test('keep 과 remove 에 같은 항목이 동시에 있으면 안 된다', async () => {
  const m = JSON.parse(await readFile('bootstrap/manifest.json', 'utf8'));
  const keepNames = m.marketplaces.keep.map((x) => x.name);
  const overlap = keepNames.filter((n) => m.marketplaces.remove.includes(n));
  assert.deepEqual(overlap, [], `마켓플레이스가 keep/remove 양쪽에 있다: ${overlap}`);

  const keepPlugins = m.plugins.keep;
  const overlapPlugins = keepPlugins.filter((n) => m.plugins.remove.includes(n));
  assert.deepEqual(overlapPlugins, []);
});

test('제거 대상 MCP 가 프로젝트 스코프로 재배치되어 있다', async () => {
  const m = JSON.parse(await readFile('bootstrap/manifest.json', 'utf8'));
  const relocated = new Set(Object.values(m.projectScoped).flatMap((p) => Object.keys(p)));
  for (const name of ['sentry', 'figma']) {
    assert.ok(relocated.has(name), `${name} 이 user 스코프에서 제거되는데 어디에도 재배치되지 않았다`);
  }
});
```

- [ ] **Step 3: 테스트 실행**

Run: `node --test scripts/bootstrap.test.mjs`
Expected: PASS — 3 tests (manifest 를 Step 1 에서 이미 만들었으므로 통과해야 한다)

- [ ] **Step 4: bootstrap.sh 작성**

```bash
#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0; DEV=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --dev) DEV=1 ;;
    *) echo "알 수 없는 옵션: $arg" >&2; exit 1 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/bootstrap/manifest.json"
run() { if [ "$DRY_RUN" = 1 ]; then echo "[dry-run] $*"; else echo "→ $*"; "$@" || true; fi; }
jq_get() { node -e "const m=require('$MANIFEST');console.log($1)"; }

echo "── 1/3 purge ──"
for p in $(jq_get "m.plugins.remove.join(' ')"); do run claude plugin uninstall "$p"; done
for mk in $(jq_get "m.marketplaces.remove.join(' ')"); do run claude plugin marketplace remove "$mk"; done
for s in $(jq_get "m.mcpServers.userScope.remove.join(' ')"); do run claude mcp remove "$s" -s user; done
run node "$ROOT/bootstrap/strip-hooks.mjs"

echo "── 2/3 install ──"
if [ "$DEV" = 1 ]; then
  run claude plugin marketplace add "$ROOT"
else
  for i in $(jq_get "m.marketplaces.keep.map((x,i)=>i).join(' ')"); do
    run claude plugin marketplace add "$(jq_get "m.marketplaces.keep[$i].source")"
  done
fi
for p in $(jq_get "m.plugins.keep.join(' ')"); do run claude plugin install "$p"; done

echo "── 3/3 project scope ──"
echo "프로젝트 스코프 MCP 는 각 레포의 .mcp.json 으로 관리한다. manifest 의 projectScoped 를 참고해 수동 배치하거나, Task 10 의 검증을 먼저 수행할 것."

echo "완료. 확인: claude plugin list / claude mcp list"
```

`chmod +x bootstrap/bootstrap.sh`

- [ ] **Step 5: settings.json 훅 제거 스크립트 작성**

`bootstrap/strip-hooks.mjs`:

```javascript
import { readFile, writeFile, copyFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';

const p = join(homedir(), '.claude/settings.json');
const s = JSON.parse(await readFile(p, 'utf8'));
if (!s.hooks) { console.log('훅 없음 — 건너뜀'); process.exit(0); }

await copyFile(p, `${p}.bak`);
let removed = 0;
for (const [event, entries] of Object.entries(s.hooks)) {
  const kept = entries.filter((entry) =>
    !(entry.hooks ?? []).some((h) => (h.command ?? '').includes('agentmemory')));
  removed += entries.length - kept.length;
  if (kept.length) s.hooks[event] = kept; else delete s.hooks[event];
}
if (!Object.keys(s.hooks).length) delete s.hooks;
await writeFile(p, JSON.stringify(s, null, 2) + '\n');
console.log(`agentmemory 중복 훅 ${removed}개 제거 (백업: ${p}.bak)`);
```

- [ ] **Step 6: env.example 작성**

```bash
# ~/.config/zizon/env 로 복사한 뒤 실제 값을 채우고,
# 셸 프로파일에 다음을 추가한다:  [ -f ~/.config/zizon/env ] && . ~/.config/zizon/env
export FIGMA_API_KEY=
```

- [ ] **Step 7: dry-run 으로 안전성 확인**

Run: `bash bootstrap/bootstrap.sh --dry-run`
Expected: 모든 명령이 `[dry-run]` 접두사로 출력되고 시스템 상태가 바뀌지 않는다

Run: `claude plugin list | wc -l`
Expected: dry-run 전후 동일

- [ ] **Step 8: 커밋**

```bash
git add bootstrap scripts/bootstrap.test.mjs
git commit -m "feat(bootstrap): 선언적 manifest + 멱등 적용 스크립트

purge → install → project-scope 3단계. --dry-run 으로 안전 확인,
--dev 로 로컬 마켓플레이스 전환.

strip-hooks.mjs 가 settings.json 의 agentmemory 중복 훅을 제거한다
(플러그인이 \${CLAUDE_PLUGIN_ROOT} 로 이미 등록 — 이중 실행 버그)."
```

---

### Task 10: sentry 프로젝트 스코프 선행 검증

전역 MCP 를 지우기 **전에** 한다. sentry 는 최다 사용(270회) MCP 이고 OAuth 인증이 프로젝트 스코프로 승계되는지 미확인이므로, 한 곳에서 먼저 확인한다.

**Files:**
- Create: `~/Desktop/jihoon-blog/.mcp.json`

**Interfaces:**
- Consumes: Task 9 의 `manifest.json` 의 `projectScoped` 정의
- Produces: 검증 결과 — 승계되면 Task 11 진행, 안 되면 스펙 §12 로 되돌려 강등 자체를 재검토

- [ ] **Step 1: jihoon-blog 에 프로젝트 스코프 sentry 추가**

`~/Desktop/jihoon-blog/.mcp.json`:

```json
{
  "mcpServers": {
    "sentry": { "type": "http", "url": "https://mcp.sentry.dev/mcp" }
  }
}
```

- [ ] **Step 2: 새 세션에서 인증 승계 확인**

jihoon-blog 에서 새 Claude Code 세션을 열고 sentry 툴을 한 번 호출한다 (예: 이슈 목록 조회).

Expected: 재인증 프롬프트 없이 동작한다.

- [ ] **Step 3: 결과에 따라 분기**

- **승계됨** → kalyx 에도 같은 `.mcp.json` 을 추가하고, mutal 에 figma 를 추가한 뒤 Task 11 로 진행한다
- **재인증 요구됨** → Task 11 의 purge 에서 `sentry` 를 제외하고, 스펙 §12 「리스크와 미결」에 결과를 기록한다. 전역 유지가 재인증 2회보다 싸다

- [ ] **Step 4: 결과를 스펙에 기록**

`docs/superpowers/specs/2026-08-25-zizon-design.md` §12 에 실측 결과 한 줄을 추가한다.

- [ ] **Step 5: 커밋**

```bash
git add docs/superpowers/specs/2026-08-25-zizon-design.md
git commit -m "docs(spec): sentry 프로젝트 스코프 인증 승계 실측 결과 기록"
```

---

### Task 11: bootstrap 실제 실행 + 전체 검증

**Files:** 없음 (시스템 상태 변경)

**Interfaces:**
- Consumes: Task 9 의 `bootstrap.sh`, Task 10 의 검증 결과

- [ ] **Step 1: 현재 상태를 기록**

```bash
claude plugin list > /tmp/before-plugins.txt
claude mcp list > /tmp/before-mcp.txt
cp ~/.claude/settings.json /tmp/before-settings.json
```

- [ ] **Step 2: 로컬 마켓플레이스로 실행 (개명 전이므로 --dev)**

Run: `bash bootstrap/bootstrap.sh --dev`

- [ ] **Step 3: 결과 확인**

Run: `claude plugin list`
Expected: 정확히 3개 — superpowers, agentmemory, zizon

Run: `claude mcp list`
Expected: user 스코프 0개 (Task 10 에서 sentry 승계가 안 됐다면 sentry 1개)

- [ ] **Step 4: 멱등성 확인 — 같은 스크립트를 한 번 더 실행**

```bash
claude plugin list > /tmp/after1.txt
bash bootstrap/bootstrap.sh --dev
claude plugin list > /tmp/after2.txt
diff /tmp/after1.txt /tmp/after2.txt && echo "멱등성 확인"
```

Expected: `멱등성 확인` — 두 번째 실행이 아무것도 바꾸지 않는다

- [ ] **Step 5: 훅 중복 해소 확인**

Run: `node -e "const s=require(require('os').homedir()+'/.claude/settings.json');console.log(JSON.stringify(s.hooks??{},null,1))"`
Expected: agentmemory 를 가리키는 훅이 없다

새 세션을 열고 agentmemory 가 이벤트당 1회만 동작하는지 확인한다.

- [ ] **Step 6: 스킬 노출 확인 — 디렉토리형 선언의 진짜 게이트**

Run: `claude plugin details zizon@zizon`
Expected: 컴포넌트 인벤토리에 스킬 19개가 잡힌다.

`claude plugin validate` 는 매니페스트 **스키마만** 검사하고 `skills` 경로가 실제로 스킬을 담고 있는지는 보지 않는다 (`./does-not-exist/` 로 바꿔도 통과함이 실측됨). 따라서 `"skills": ["./skills/"]` 디렉토리형이 실제로 동작하는지 확인하는 지점은 여기다.

19개가 아니면 `.claude-plugin/marketplace.json` 의 `skills` 를 개별 경로 19개 나열로 바꾸고 재설치한다.

이어서 새 세션에서 스킬 목록에 zizon 스킬 19개가 보이는지 확인한다.

- [ ] **Step 7: 실패 시 롤백 경로**

문제가 있으면 `/tmp/before-settings.json` 을 되돌리고 `claude plugin marketplace add <원래 source>` 로 복구한다. 삭제한 스킬은 git 히스토리에 있다.

---

### Task 12: 문서 갱신

**Files:**
- Modify: `README.md`, `README.en.md`, `AGENTS.md`, `AGENTS.ko.md`, `package.json`

**Interfaces:**
- Consumes: Task 3 의 버킷 구조, Task 4 의 설치 명령

- [ ] **Step 1: README 한/영 갱신**

인덱스 표를 새 구조로 바꾼다. `runtimes/`, `mcp/` 행을 지우고 `bootstrap/` 행을 넣는다. 설치 명령을 교체한다:

```text
/plugin marketplace add devjh-jiki/zizon
/plugin install zizon@zizon
```

Codex 설치 안내(`npx skills@latest add ...`)와 `.agents/skills` 설명을 삭제한다 — Claude Code 전용 결정.

`cathrynlavery/diagram-design` 추천 섹션 옆에 `pbakaus/impeccable` 을 같은 형식으로 추가한다 (복사하지 않고 원본 설치 권장).

- [ ] **Step 2: AGENTS 한/영 갱신**

- Repository Map 에서 `runtimes/`, `.agents/`, `mcp/` 항목을 지우고 `bootstrap/`, `scripts/` 를 넣는다
- Skill Contract 의 경로를 `skills/<bucket>/<skill-name>/SKILL.md` 로 바꾸고 허용 버킷 7개를 명시한다
- 문서 페어 규칙 면제 목록에 `docs/superpowers/` 를 추가한다 (스펙 §12 의 미결 항목)
- Verification 절의 Codex 심볼릭 링크 검사를 `pnpm validate && pnpm test` 로 교체한다

- [ ] **Step 3: 삭제된 스킬을 가리키는 잔존 참조 전수 수정**

Task 2 가 지운 19개 스킬을 아직 가리키는 곳이 남아 있다. 계획이 만든 잔재이며 어느 태스크에도 배정되지 않았다.

- `skills/README.md` / `skills/README.ko.md` — 버킷 인덱스가 옛 5버킷 구조와 삭제된 16개 스킬을 그대로 나열한다. 7버킷 19스킬 구조로 재작성한다.
- 스킬 본문의 상호 참조 6곳:
  - `skills/testing/webapp-testing/SKILL.md` → 없는 `tdd` (의도는 `superpowers:test-driven-development`)
  - `skills/planning/implement/SKILL.ko.md` → `tdd`
  - `skills/token/lazy-code/SKILL.ko.md` → `diagnosing-bugs`
  - `skills/planning/to-issues/SKILL.md` → `prototype`
  - `skills/design/anti-slop-frontend/SKILL.ko.md` → `design-system`
  - `skills/token/context-budget/SKILL.ko.md` → `iterative-retrieval`
  - `skills/planning/codebase-design/SKILL.md` → `improve-codebase-architecture`

살아남은 대응물이 있으면 그쪽으로, 외부 플러그인이 대체하면 `superpowers:<name>` 형태로, 대응물이 없으면 문장째 삭제한다. 한/영 쌍 양쪽을 함께 고친다.

검증:
```bash
for d in tdd diagnosing-bugs handoff writing-great-skills verification-before-completion          grill-with-docs council prototype eval-harness design-system document-with-research          write-blog-post setup-pre-commit recency-research iterative-retrieval improve-codebase-architecture; do
  grep -rln "\b$d\b" skills/ 2>/dev/null | grep -v "$d/" | sed "s/^/$d: /"
done
```
Expected: `superpowers:` 접두사가 붙은 의도적 참조만 남고 나머지는 출력 없음

- [ ] **Step 4: package.json 이름 변경**

`"name": "@dev-hub/skills"` → `"name": "@zizon/skills"`, description 도 갱신한다.

- [ ] **Step 5: 검증**

Run: `pnpm validate && pnpm test`
Expected: 통과

Run: `bash -c 'find . -name "*.md" -not -name "*.ko.md" -not -name "*.en.md" -not -path "./.git/*" -not -path "./.upstream/*" -not -path "*/node_modules/*" -not -path "./docs/superpowers/*" -not -name "CLAUDE.md" -not -name "THIRD_PARTY_NOTICES.md" -not -path "./.changeset/*" -not -path "./templates/*" -not -name "README.md" | while read f; do [ -f "${f%.md}.ko.md" ] || echo "쌍 없음: $f"; done'`
Expected: 출력 없음

- [ ] **Step 6: 커밋**

```bash
git add README.md README.en.md AGENTS.md AGENTS.ko.md package.json skills/README.md skills/README.ko.md skills/
git commit -m "docs: zizon 개명과 새 구조 반영

인덱스·설치 명령·Repository Map 갱신. Codex 안내 삭제(Claude Code
전용). 문서 페어 면제에 docs/superpowers/ 추가. impeccable 을 추천
설치 항목으로 등록."
```

---

### Task 13: 레포 개명과 최종 전환

**Files:** 없음 (GitHub·로컬 경로 변경)

- [ ] **Step 1: 브랜치를 main 에 머지**

```bash
pnpm validate && pnpm test
git checkout main
git merge --no-ff design/zizon-consolidation
git push origin main
```

- [ ] **Step 2: CI 통과 확인**

Run: `gh run list --limit 3`
Expected: `check-doc-pairs` 통과

- [ ] **Step 3: GitHub 레포 개명**

```bash
gh repo rename zizon --repo devjh-jiki/jiki
```

star 0 / fork 0 이므로 깨질 외부 설치가 없고, GitHub 이 이전 URL 에 리다이렉트를 건다.

- [ ] **Step 4: 로컬 remote 와 폴더명 갱신**

```bash
git remote set-url origin https://github.com/devjh-jiki/zizon.git
cd .. && mv dev-hub zizon && cd zizon
git remote -v
```

- [ ] **Step 5: GitHub 마켓플레이스로 재설치 (--dev 해제)**

```bash
claude plugin marketplace remove zizon
bash bootstrap/bootstrap.sh
```

Run: `claude plugin list`
Expected: 3개 — superpowers, agentmemory, zizon (source 가 GitHub)

- [ ] **Step 6: 최종 검증 체크리스트**

- [ ] `claude plugin list` 가 정확히 3개
- [ ] `claude mcp list` 의 user 스코프가 0개
- [ ] 새 세션에서 zizon 스킬 19개가 보인다
- [ ] agentmemory 훅이 이벤트당 1회만 실행된다
- [ ] jihoon-blog 에서 sentry, mutal 에서 figma 가 프로젝트 스코프로 잡힌다
- [ ] `bootstrap.sh` 를 새로 clone 한 곳에서 실행해도 같은 결과가 나온다

- [ ] **Step 7: 메모리 갱신**

`~/.claude/projects/-Users-lsy6234naver-com-Desktop/memory/` 의 `MEMORY.md` 와 관련 메모리에서 `dev-hub` 를 `zizon` 으로, 경로를 새 위치로 갱신한다.

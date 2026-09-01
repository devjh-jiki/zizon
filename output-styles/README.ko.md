# Output Styles

> English: [README.md](./README.md)

`skills/` 는 필요할 때 불려 나오고, 여기 있는 output-style 은 켜져 있는 동안 항상 걸립니다.
그래서 평범한 답변 한 줄의 한국어에 개입할 수 있는 수단은 이쪽뿐입니다.

## 등재된 스타일

- [fluent-korean](./fluent-korean.md). 조사·어미가 뭉개지고 명사구로 문장이 끝나는 현상을 막습니다. [snflkd/fluent-korean](https://github.com/snflkd/fluent-korean) (MIT) 적응

## 켜는 법

이 레포는 버전을 올리지 않으므로 `plugin update` 로는 반영되지 않는다. 재설치한다.

```
claude plugin marketplace update zizon
claude plugin uninstall zizon@zizon && claude plugin install zizon@zizon
```

그다음 `~/.claude/settings.json` 에 이름을 직접 적는다.
**`fluent-korean` 이 아니라 `zizon:fluent-korean` 이다.** Claude Code 가 플러그인이 공급한 스타일의
키를 `${플러그인명}:${frontmatter 의 name}` 으로 만든다.

```json
{ "outputStyle": "zizon:fluent-korean" }
```

넣은 뒤 새 세션으로 들어가야 한다. 스타일은 시작할 때 읽는다.
되돌릴 때는 그 키를 지운다.

고치는 중이라면 push 없이 `./bootstrap/bootstrap.sh --dev` 로 로컬 소스를 보게 할 수 있다.

### 2.1.236 에서 확인한 것

이 절이 없으면 다음 사람이 같은 자리에서 세 번 막힌다. 실제로 세 번 막혔다.

- **`/output-style` 슬래시 명령은 없다.** `/config` 안의 항목이다
- **`/config` 의 드롭다운은 내장 스타일만 나열한다.** 항목 정의가 `options: Object.keys(xke)` 이고
  `xke` 는 내장 목록이다. 커스텀 스타일은 설정 파일로만 지정된다
- **이름에 플러그인 접두사가 붙는다.** 번들의 `sDp` 가 `` `${t}:${l}` `` 로 키를 만든다.
  접두사 없는 이름을 넣으면 조용히 무시되고 기본 스타일로 돌아간다

`~/.claude/output-styles/` 사용자 디렉터리는 쓰지 않는 편이 안전하다. 스타일 목록을 만드는 함수
(`aDp`)가 활성 플러그인의 `outputStylesPath` 만 훑고 사용자 홈을 보는 코드가 보이지 않는다.
다만 이것은 코드를 읽은 결과이고 실측으로 확정하지는 못했다.

## 왜 원본을 그대로 설치하지 않았나

이 레포는 외부 플러그인을 복사하지 않는 것을 기본으로 삼습니다(README 의 「외부 추천 플러그인」).
원본을 그대로 설치하면 업데이트와 검증 체계를 그대로 따를 수 있기 때문입니다.

fluent-korean 은 예외로 뒀습니다. **이 레포 안의 다른 자산과 정면으로 충돌하는 지점이 있어서
조항을 더하지 않으면 켤 수 없기 때문**입니다. 복사의 기준을 이렇게 잡습니다.
고칠 것이 없으면 원본을 설치하고, 고쳐야만 쓸 수 있으면 여기로 가져와 출처를 남깁니다.

충돌은 둘이었습니다.

**문체.** 원본 「구 단위」 1의 목표 예시가 최대로 늘린 합쇼체입니다.
이 레포의 스킬과 `vault` 의 문서는 전부 짧은 해라체입니다. 그대로 켜면 문서가 원본 예시의 어투를 따라갑니다.

**압축.** `token/terse-output` 과 `token/i-have-adhd` 는 문장을 줄이라고 지시하고,
원본은 조사와 어미를 되살리라고 지시합니다. 같은 자리에서 반대로 당깁니다.

## 무엇을 고쳤나

원본 「동작 범위」에 조항 세 개를 더한 것이 전부입니다. 본문 규칙은 한 글자도 건드리지 않았습니다.
원본 2번 조항이 이미 코드에 속하는 텍스트를 프로젝트 관례에 넘기고 있어서, 그 형제 조항의 형태로 붙였습니다.

| 조항 | 내용 | 막는 것 |
|---|---|---|
| 5 | Write·Edit 로 파일이 되는 텍스트는 그 프로젝트의 작성 기준을 따른다. 기준이 없는 파일에는 본문 지침을 그대로 적용한다 | 문체 충돌 |
| 6 | 파일에 들어갈 텍스트를 채팅에서 미리 보여줄 때는 최종 형태 그대로 보여준다 | 초안과 최종본의 문체가 갈라지는 것 |
| 7 | 사용자가 압축을 명시적으로 요청하면 그쪽이 우선한다 | terse-output·i-have-adhd 충돌 |

경계를 「문서 대 답변」이 아니라 **「파일에 쓰는 텍스트 대 채팅에 말하는 텍스트」**로 자른 이유가 있습니다.
앞의 것은 매번 모델이 판단해야 하고 뒤의 것은 도구 호출로 갈립니다.

## 원본이 갱신되면

`.github/workflows/sync-upstream-skills.yml` 의 매트릭스에 등록해 뒀습니다.
매주 월요일에 원본을 `.upstream/snflkd-fluent-korean/` 으로 받아 놓고, 달라진 것이 있을 때만 커밋합니다.
스킬이 아니라 output-style 이라 `path` 가 `skills` 가 아닌 `plugins/fluent-korean/output-styles` 입니다.

**자동으로 머지하지 않습니다.** 이 레포의 기존 정책과 같습니다.
스냅샷이 갱신되면 무엇이 달라졌는지 이렇게 봅니다.

```bash
diff .upstream/snflkd-fluent-korean/fluent-korean.md output-styles/fluent-korean.md
```

조항 5·6·7 은 이쪽에만 있으므로 항상 차이로 잡힙니다. 그 셋을 뺀 나머지가 반영할 후보입니다.
포크 기준선은 커밋 `ce8683f` (2026-08-23) 이고 `THIRD_PARTY_NOTICES.md` 에 적혀 있습니다.

## 안 되는 것

**맞춤법 검사가 아닙니다.** 원본에 철자 규칙이 한 줄도 없습니다.
조사·어미가 뭉개지며 생기는 오타는 줄지만, 그 밖의 오타는 그대로 남습니다.

**긴 작업에서 효과가 떨어집니다.** 원본 README 가 스스로 적어 둔 한계입니다.

## 검토했다가 넣지 않은 것

- [epoko77-ai/im-not-ai](https://github.com/epoko77-ai/im-not-ai). 다 쓴 글을 사후에 윤문합니다.
  변경률 30% 경고와 50% 강제 중단 게이트를 걸고 칼럼·에세이 장르를 겨냥하므로,
  짧은 해라체 도메인 문서에 돌리면 일부러 고른 문체를 훼손합니다
- [DaleSeo/korean-skills](https://github.com/DaleSeo/korean-skills). 셋 중 `grammar-checker` 하나만 오타 문제를 건드립니다.
  스킬이라 답변에는 개입하지 못하므로 지금은 보류하고, 문서 맞춤법이 실제로 문제가 되면 그때 다시 봅니다

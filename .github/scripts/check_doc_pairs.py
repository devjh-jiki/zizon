#!/usr/bin/env python3
"""한/영 문서 쌍 검사.

로컬에서도 그대로 돌린다.

    python3 .github/scripts/check_doc_pairs.py

검사 셋의 근거는 `.github/workflows/check-doc-pairs.yml` 의 주석에 있다.
요지는 하나다. **존재를 세지 않고 어긋남을 본다.**
"""

import os
import re
import sys

SKIP_DIRS = {".git", "node_modules", ".upstream", ".superpowers"}

FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.S)
FENCE = re.compile(r"^(```|~~~).*?^\1", re.S | re.M)
HEADING = re.compile(r"^(#{1,6}) \S", re.M)
QUOTED = re.compile(r'"[^"]*"|\'[^\']*\'')
HANGUL = re.compile(r"[가-힣]")

# 한국어 비중이 이 값을 넘으면 description 이 한국어로 쓰였다고 본다.
# 따옴표로 감싼 한국어 트리거 문구는 세기 전에 지우므로 정상 스킬은 0% 에 가깝다.
KO_DESCRIPTION_LIMIT = 15


def walk_md():
    for root, dirs, files in os.walk("."):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            if f.endswith(".md"):
                yield os.path.join(root, f)


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def frontmatter(text):
    m = FRONTMATTER.match(text)
    return m.group(1) if m else ""


def body(text):
    text = FRONTMATTER.sub("", text)
    return FENCE.sub("", text)


def headings(text):
    """제목의 깊이만 순서대로 뽑는다. 제목 글자는 번역되므로 비교 대상이 아니다."""
    return [m.group(1) for m in HEADING.finditer(body(text))]


def description(fm):
    m = re.search(r"^description:\s*(.*(?:\n[ \t]+.*)*)", fm, re.M)
    return m.group(1) if m else ""


def hangul_ratio(s):
    s = QUOTED.sub("", s)
    s = re.sub(r"\s", "", s)
    if not s:
        return 0
    return len(HANGUL.findall(s)) * 100 // len(s)


def main():
    errors = []
    paths = sorted(walk_md())

    # ── A. SKILL.md 의 description 은 영어여야 한다
    #    Claude 가 스킬을 고를 때 읽는 값이다. 한국어로 쓰면 영어 프롬프트에 안 걸린다.
    #    따옴표 안의 한국어 트리거 문구는 오히려 권장하므로 세지 않는다.
    for p in paths:
        if os.path.basename(p) != "SKILL.md":
            continue
        d = description(frontmatter(read(p)))
        if not d.strip():
            errors.append(f"{p}: frontmatter 에 description 이 없습니다")
        elif hangul_ratio(d) >= KO_DESCRIPTION_LIMIT:
            errors.append(
                f"{p}: description 이 한국어입니다. Claude 가 스킬을 고를 때 읽는 값이라 "
                f"영어로 쓰고, 한국어 트리거는 따옴표 안에 예시로 넣습니다"
            )

    # ── B. 짝 없는 .ko.md 가 없어야 한다
    #    원본을 지우거나 옮기고 번역만 남긴 경우다.
    for p in paths:
        if p.endswith(".ko.md") and not os.path.exists(p[: -len(".ko.md")] + ".md"):
            errors.append(f"{p}: 짝이 되는 원본 {p[:-len('.ko.md')]}.md 가 없습니다")

    # ── C. 번역은 원본의 구조를 따라와야 한다
    #    .ko.md 를 만드는 것은 의무가 아니다. 만들었으면 따라와야 한다.
    #    제목 글자는 번역되므로 깊이의 나열만 비교한다.
    #
    #    예외를 선언으로 만든다. 요점만 옮기고 상세는 원본에 맡기는 번역이 실제로 있고,
    #    그것은 낡은 것이 아니라 고른 것이다. 다만 **고른 것과 낡은 것을 사람이 읽어야만
    #    구분되면 검사가 값을 못 한다.** 그래서 축약본은 frontmatter 에 선언한다.
    #
    #        translation: abridged
    #
    #    선언이 없으면 전체 번역으로 보고 구조 일치를 요구한다. 선언은 지우기도 쉽고
    #    grep 도 되므로, 나중에 전체 번역으로 올릴 때 무엇을 올려야 하는지가 목록으로 남는다.
    pairs = [(p[: -len(".ko.md")] + ".md", p) for p in paths if p.endswith(".ko.md")]
    if os.path.exists("README.md") and os.path.exists("README.en.md"):
        pairs.append(("README.md", "README.en.md"))

    abridged = []
    for src, tr in pairs:
        if not os.path.exists(src):
            continue  # B 가 이미 보고했다
        text = read(tr)
        # 값 뒤의 YAML 주석(`# 왜 축약했는지`)을 허용한다. 이유를 적을 자리가 있어야 한다
        if re.search(r"^translation:[ \t]*abridged[ \t]*(#.*)?$", frontmatter(text), re.M):
            abridged.append(tr)
            continue
        a, b = headings(read(src)), headings(text)
        if a != b:
            errors.append(
                f"{tr}: 제목 구조가 {src} 와 다릅니다 (원본 {len(a)}개 / 번역 {len(b)}개). "
                f"절이 한쪽에만 있으면 번역이 낡은 것입니다. 요약본이 의도라면 "
                f"frontmatter 에 `translation: abridged` 를 선언하세요"
            )

    if errors:
        for e in errors:
            print(f"::error::{e}" if os.environ.get("GITHUB_ACTIONS") else f"  {e}")
        print(f"\n{len(errors)}건. CLAUDE.md 의 「한/영 문서 페어 규칙」을 확인하세요.")
        return 1

    print(f"문서 {len(paths)}개, 쌍 {len(pairs)}개. 모두 통과.")
    if abridged:
        print(f"축약 선언 {len(abridged)}개 (구조 일치 검사 제외):")
        for p in abridged:
            print(f"  {p}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

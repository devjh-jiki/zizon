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

FAILURES=0

# manifest 의 문자열 배열을 한 줄에 한 항목씩 출력한다. $(...) 의 기본 단어분리(word
# splitting)에 기대지 않고 `while IFS= read -r` 로 순회하므로, 값에 공백이나 따옴표가
# 있어도 항목 하나가 추가 인자로 쪼개지지 않는다.
jq_list() {
  node -e "
    const m = require('$MANIFEST');
    for (const x of ($1)) process.stdout.write(String(x) + '\n');
  "
}

# marketplaces.keep 의 {name, source} 쌍을 'name<TAB>source' 형태로 한 줄씩 출력한다.
jq_pairs() {
  node -e "
    const m = require('$MANIFEST');
    for (const x of ($1)) process.stdout.write(x.name + '\t' + x.source + '\n');
  "
}

# run(): dry-run 이면 그대로 출력만 하고 아무것도 실행하지 않는다.
# 실행 모드에서는 종료코드로 세 가지를 구분한다:
#   0        → 성공 (그대로 진행)
#   0 이 아님 + 출력이 "이미 그 상태" 류 문구를 포함 → 멱등 — 목표 상태에 이미 도달, 계속 진행
#   0 이 아님 + 그 외                                → 진짜 실패 — 큰 소리로 보고하고 FAILURES 누적
# `|| true` 로 모든 실패를 무조건 삼키던 방식과 달리, 이 함수는 "이미 끝난 상태"와
# "명령이 정말로 실패함"을 구분해서 후자만 실패로 센다.
run() {
  if [ "$DRY_RUN" = 1 ]; then
    echo "[dry-run] $*"
    return 0
  fi
  echo "→ $*"
  local out status
  set +e
  out="$("$@" 2>&1)"
  status=$?
  set -e
  if [ "$status" -eq 0 ]; then
    [ -n "$out" ] && echo "$out"
    return 0
  fi
  if echo "$out" | grep -qiE 'already (exists|added|installed|present|configured)|not (found|installed|exist(s)?|present|configured)|no such|unknown (marketplace|plugin|server)|does not exist'; then
    echo "  (이미 목표 상태로 판단 — 건너뜀) $out"
    return 0
  fi
  echo "  [실패] exit=$status: $out" >&2
  FAILURES=$((FAILURES + 1))
  return 0
}

echo "── 1/3 purge ──"
while IFS= read -r p; do [ -n "$p" ] && run claude plugin uninstall "$p"; done < <(jq_list "m.plugins.remove")
while IFS= read -r mk; do [ -n "$mk" ] && run claude plugin marketplace remove "$mk"; done < <(jq_list "m.marketplaces.remove")
while IFS= read -r s; do [ -n "$s" ] && run claude mcp remove "$s" -s user; done < <(jq_list "m.mcpServers.userScope.remove")
run node "$ROOT/bootstrap/strip-hooks.mjs"

echo "── 2/3 install ──"
# --dev 는 zizon 마켓플레이스의 출처만 로컬 디렉터리로 바꾼다. claude-plugins-official 과
# agentmemory 는 --dev 여부와 무관하게 정상 출처(GitHub)에서 추가해야 superpowers/agentmemory
# 플러그인 설치가 마켓플레이스를 찾을 수 있다 (R2: 기존 if/else 이분기는 --dev 일 때 이 둘을
# 건너뛰어 뒤따르는 `claude plugin install superpowers@claude-plugins-official` 이 실패했다).
while IFS=$'\t' read -r name source; do
  [ -z "$name" ] && continue
  if [ "$DEV" = 1 ] && [ "$name" = "zizon" ]; then
    run claude plugin marketplace add "$ROOT"
  else
    run claude plugin marketplace add "$source"
  fi
done < <(jq_pairs "m.marketplaces.keep")
while IFS= read -r p; do [ -n "$p" ] && run claude plugin install "$p"; done < <(jq_list "m.plugins.keep")

echo "── 3/3 project scope ──"
echo "프로젝트 스코프 MCP 는 각 레포의 .mcp.json 으로 관리한다. manifest 의 projectScoped 를 참고해 수동 배치하거나, Task 10 의 검증을 먼저 수행할 것."

if [ "$FAILURES" -gt 0 ]; then
  echo "완료했으나 ${FAILURES}건 실패 — 위 [실패] 로그를 확인할 것." >&2
  exit 1
fi
echo "완료. 확인: claude plugin list / claude mcp list"

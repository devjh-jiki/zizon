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

# claude 가 PATH 에 없거나 응답하지 않으면 이후의 모든 명령이 "command not found" 로
# 실패한다. 그 텍스트가 아래 검증 로직의 "이미 없음" 판정과 우연히 겹칠 수 있으므로,
# 어떤 동작도 시작하기 전에 claude 가 실제로 살아있는지 먼저 확인한다. 여기서 걸리면
# 아무것도 건드리지 않고 즉시 중단한다 — dry-run 이어도 마찬가지로 검사한다(읽기 전용
# 점검이라 상태를 바꾸지 않는다).
if ! command -v claude >/dev/null 2>&1; then
  echo "오류: claude 명령을 PATH 에서 찾을 수 없다. 아무 작업도 하지 않고 중단한다." >&2
  exit 1
fi
if ! claude --version >/dev/null 2>&1; then
  echo "오류: claude --version 실행이 실패했다 — claude 바이너리가 정상 동작하지 않는다. 아무 작업도 하지 않고 중단한다." >&2
  exit 1
fi

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

# ── 상태 재조회 헬퍼 ──────────────────────────────────────────────────────
# CLI 실패 메시지의 문구를 추정해서 "이미 목표 상태"인지 판단하지 않는다 (그 방식은
# claude 바이너리 자체가 없을 때 나오는 "command not found" 도 우연히 무해한 문구와
# 겹칠 수 있어 위험하다고 지적받았다). 대신 명령이 실패하면 실제 상태를 다시 물어봐서 목표가 이미
# 달성됐는지 확인한다. 세 헬퍼 모두 "그 항목이 지금 존재하는가?" 를 종료코드로 답한다
# (0 = 존재함). ensure_absent/ensure_present 가 이 답을 보고 이미 목표 상태인지(무해)를 정한다.
installed_plugins() { claude plugin list 2>/dev/null | sed -n 's/^[[:space:]]*❯[[:space:]]*//p'; }
configured_marketplaces() { claude plugin marketplace list 2>/dev/null | sed -n 's/^[[:space:]]*❯[[:space:]]*//p'; }
plugin_installed() { installed_plugins | grep -qxF -- "$1"; }
marketplace_configured() { configured_marketplaces | grep -qxF -- "$1"; }
mcp_in_user_scope() {
  local out
  out="$(claude mcp get "$1" 2>&1)" || return 1
  printf '%s\n' "$out" | grep -q 'Scope: User config'
}

# ensure_absent <검증함수> <검증인자> <실행할 커맨드...>
#   커맨드가 실패하면 검증함수로 "그 항목이 아직도 있는가" 재조회한다.
#   없으면(검증함수가 1) 이미 목표 상태였던 것 — 무해. 있으면 진짜 실패.
ensure_absent() {
  local check="$1" arg="$2"; shift 2
  if [ "$DRY_RUN" = 1 ]; then echo "[dry-run] $*"; return 0; fi
  echo "→ $*"
  local out status
  set +e; out="$("$@" 2>&1)"; status=$?; set -e
  if [ "$status" -eq 0 ]; then
    [ -n "$out" ] && echo "$out"
    return 0
  fi
  if ! "$check" "$arg"; then
    echo "  (재조회 결과 이미 부재함 — 목표 상태, 건너뜀) exit=$status: $out"
    return 0
  fi
  echo "  [실패] exit=$status: $out (재조회 결과 여전히 존재함)" >&2
  FAILURES=$((FAILURES + 1))
}

# ensure_present <검증함수> <검증인자> <실행할 커맨드...>
#   커맨드가 실패하면 검증함수로 "그 항목이 이미 있는가" 재조회한다.
#   있으면(검증함수가 0) 이미 목표 상태였던 것 — 무해. 없으면 진짜 실패.
ensure_present() {
  local check="$1" arg="$2"; shift 2
  if [ "$DRY_RUN" = 1 ]; then echo "[dry-run] $*"; return 0; fi
  echo "→ $*"
  local out status
  set +e; out="$("$@" 2>&1)"; status=$?; set -e
  if [ "$status" -eq 0 ]; then
    [ -n "$out" ] && echo "$out"
    return 0
  fi
  if "$check" "$arg"; then
    echo "  (재조회 결과 이미 존재함 — 목표 상태, 건너뜀) exit=$status: $out"
    return 0
  fi
  echo "  [실패] exit=$status: $out (재조회 결과 여전히 부재함)" >&2
  FAILURES=$((FAILURES + 1))
}

# run_required <실행할 커맨드...>
#   상태를 되물어볼 방법이 없는 커맨드(예: strip-hooks.mjs)용. exit 0 만 성공으로
#   본다 — 문구 추정도, 무해 판정도 없다. "재조회가 불가능하면 실패로 간주한다"
#   원칙을 그대로 적용한 것.
run_required() {
  if [ "$DRY_RUN" = 1 ]; then echo "[dry-run] $*"; return 0; fi
  echo "→ $*"
  local out status
  set +e; out="$("$@" 2>&1)"; status=$?; set -e
  if [ "$status" -eq 0 ]; then
    [ -n "$out" ] && echo "$out"
    return 0
  fi
  echo "  [실패] exit=$status: $out" >&2
  FAILURES=$((FAILURES + 1))
}

echo "── 1/3 purge ──"
while IFS= read -r p; do [ -n "$p" ] && ensure_absent plugin_installed "$p" claude plugin uninstall "$p"; done < <(jq_list "m.plugins.remove")
while IFS= read -r mk; do [ -n "$mk" ] && ensure_absent marketplace_configured "$mk" claude plugin marketplace remove "$mk"; done < <(jq_list "m.marketplaces.remove")
while IFS= read -r s; do [ -n "$s" ] && ensure_absent mcp_in_user_scope "$s" claude mcp remove "$s" -s user; done < <(jq_list "m.mcpServers.userScope.remove")
run_required node "$ROOT/bootstrap/strip-hooks.mjs"

echo "── 2/3 install ──"
# --dev 는 zizon 마켓플레이스의 출처만 로컬 디렉터리로 바꾼다. claude-plugins-official 과
# agentmemory 는 --dev 여부와 무관하게 정상 출처(GitHub)에서 추가해야 superpowers/agentmemory
# 플러그인 설치가 마켓플레이스를 찾을 수 있다 (R2: 기존 if/else 이분기는 --dev 일 때 이 둘을
# 건너뛰어 뒤따르는 `claude plugin install superpowers@claude-plugins-official` 이 실패했다).
while IFS=$'\t' read -r name source; do
  [ -z "$name" ] && continue
  if [ "$DEV" = 1 ] && [ "$name" = "zizon" ]; then
    ensure_present marketplace_configured "$name" claude plugin marketplace add "$ROOT"
  else
    ensure_present marketplace_configured "$name" claude plugin marketplace add "$source"
  fi
done < <(jq_pairs "m.marketplaces.keep")
while IFS= read -r p; do [ -n "$p" ] && ensure_present plugin_installed "$p" claude plugin install "$p"; done < <(jq_list "m.plugins.keep")

echo "── 3/3 project scope ──"
echo "프로젝트 스코프 MCP 는 각 레포의 .mcp.json 으로 관리한다. manifest 의 projectScoped 를 참고해 수동 배치하거나, Task 10 의 검증을 먼저 수행할 것."

if [ "$FAILURES" -gt 0 ]; then
  echo "실패: ${FAILURES}건 — 위 [실패] 로그를 확인할 것. claude plugin list / claude mcp list 로 실제 상태를 점검하라." >&2
  exit 1
fi
echo "완료. 확인: claude plugin list / claude mcp list"

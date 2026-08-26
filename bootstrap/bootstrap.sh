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
# CLI 실패 메시지의 문구를 추정해서 "이미 목표 상태"인지 판단하지 않는다. round 1 은
# 그렇게 했다가, 조회 자체가 실패했을 때(예: ~/.claude.json 손상)도 "출력이 비어있음
# = 부재함" 으로 잘못 읽는 문제가 남아있었다 — claude --version 은 그 파일을 안 읽어서
# 사전가드는 통과하지만, plugin list/marketplace list/mcp get 은 전부 비정상 종료하고,
# 빈 출력을 grep 하면 "없음" 과 구분이 안 됐다. 그래서 present(0)/absent(1)/unknown(2)
# 세 상태를 종료코드로 명시적으로 구분한다:
#   - list 계열(plugin list, marketplace list)은 정상 상황에서 결과가 비어 있어도
#     반드시 exit 0 이다(실측 확인: "No plugins installed"/"No marketplaces configured"
#     도 exit 0). 그러므로 이 둘의 exit 이 0 이 아니면 무조건 unknown(2) — "없다" 로
#     읽지 않는다.
#   - mcp get 은 "그 이름의 서버가 없다" 를 exit 1 + "No MCP server named" 문구로
#     정상적으로 표현한다(실측 확인). 이 특정 조합만 absent(1) 로 인정하고, 그 외의
#     비정상 종료(예: 설정 파일 손상으로 인한 종료)는 unknown(2) 으로 본다.
# 각 헬퍼 내부의 `set +e`/`set -e` 는 필수다 — 없으면 claude 가 비정상 종료할 때
# `set -e` 가 그 즉시 함수를 통째로 죽여 return 2 조차 실행되지 못하고, 그 raw exit
# 코드가 호출부로 새어나가 의미를 왜곡한다(직접 재현해 확인함, fix 보고서 참고).
plugin_installed() {
  local out status
  set +e; out="$(claude plugin list 2>&1)"; status=$?; set -e
  if [ "$status" -ne 0 ]; then
    printf '%s\n' "$out"
    return 2
  fi
  printf '%s\n' "$out" | sed -n 's/^[[:space:]]*❯[[:space:]]*//p' | grep -qxF -- "$1" && return 0
  return 1
}
marketplace_configured() {
  local out status
  set +e; out="$(claude plugin marketplace list 2>&1)"; status=$?; set -e
  if [ "$status" -ne 0 ]; then
    printf '%s\n' "$out"
    return 2
  fi
  printf '%s\n' "$out" | sed -n 's/^[[:space:]]*❯[[:space:]]*//p' | grep -qxF -- "$1" && return 0
  return 1
}
mcp_in_user_scope() {
  local out status
  set +e; out="$(claude mcp get "$1" 2>&1)"; status=$?; set -e
  if [ "$status" -eq 0 ]; then
    printf '%s\n' "$out" | grep -q 'Scope: User config' && return 0
    return 1
  fi
  printf '%s\n' "$out" | grep -q 'No MCP server named' && return 1
  printf '%s\n' "$out"
  return 2
}

# ensure_absent <검증함수> <검증인자> <실행할 커맨드...>
#   커맨드가 실패하면 검증함수로 "그 항목이 아직도 있는가" 재조회한다.
#   1(확인된 부재) 만 무해. 0(여전히 존재) 과 2(재조회 자체 실패=unknown) 는 둘 다 실패로 센다.
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
  local check_out check_status
  set +e; check_out="$("$check" "$arg")"; check_status=$?; set -e
  if [ "$check_status" -eq 1 ]; then
    echo "  (재조회 결과 이미 부재함 — 목표 상태, 건너뜀) exit=$status: $out"
    return 0
  fi
  if [ "$check_status" -eq 0 ]; then
    echo "  [실패] exit=$status: $out (재조회 결과 여전히 존재함)" >&2
  else
    echo "  [실패] exit=$status: $out (상태 재조회 자체가 실패 — unknown 은 실패로 간주) 재조회 출력: $check_out" >&2
  fi
  FAILURES=$((FAILURES + 1))
}

# ensure_present <검증함수> <검증인자> <실행할 커맨드...>
#   커맨드가 실패하면 검증함수로 "그 항목이 이미 있는가" 재조회한다.
#   0(확인된 존재) 만 무해. 1(여전히 부재) 과 2(unknown) 는 둘 다 실패로 센다.
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
  local check_out check_status
  set +e; check_out="$("$check" "$arg")"; check_status=$?; set -e
  if [ "$check_status" -eq 0 ]; then
    echo "  (재조회 결과 이미 존재함 — 목표 상태, 건너뜀) exit=$status: $out"
    return 0
  fi
  if [ "$check_status" -eq 1 ]; then
    echo "  [실패] exit=$status: $out (재조회 결과 여전히 부재함)" >&2
  else
    echo "  [실패] exit=$status: $out (상태 재조회 자체가 실패 — unknown 은 실패로 간주) 재조회 출력: $check_out" >&2
  fi
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

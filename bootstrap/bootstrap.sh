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
# 실패한다. 어떤 동작도 시작하기 전에 claude 가 실제로 살아있는지 먼저 확인한다.
# 여기서 걸리면 아무것도 건드리지 않고 즉시 중단한다 — dry-run 이어도 마찬가지로
# 검사한다(읽기 전용 점검이라 상태를 바꾸지 않는다).
if ! command -v claude >/dev/null 2>&1; then
  echo "오류: claude 명령을 PATH 에서 찾을 수 없다. 아무 작업도 하지 않고 중단한다." >&2
  exit 1
fi
if ! claude --version >/dev/null 2>&1; then
  echo "오류: claude --version 실행이 실패했다 — claude 바이너리가 정상 동작하지 않는다. 아무 작업도 하지 않고 중단한다." >&2
  exit 1
fi

FAILURES=0

# ── manifest 를 시작 시 딱 한 번 로드·검증한다 ──────────────────────────────
# round 3 리뷰가 잡아낸 문제: 이전에는 jq_list/jq_pairs 가 각 while 루프의
# `< <(...)` (프로세스 치환) 안에서 매번 새로 `node -e` 를 호출했다. `set -e` 와
# `pipefail` 은 foreground 커맨드와 파이프라인만 관찰하고, 프로세스 치환 서브셸의
# 종료코드는 아무도 거두지 않는다 — manifest.json 이 깨져있거나(JSON 파싱 실패)
# 스크립트가 의존하는 키 경로가 없어서(예: 오타로 리네임) node 가 예외로 죽으면,
# stdout 없이 exit != 0 이 되고 `while read` 는 그냥 EOF 로 보고 0번 순회한다.
# FAILURES 는 절대 증가하지 않고, 같은 실행에서 다른 정상 카테고리는 평소처럼
# [dry-run]/실행 로그를 찍어서 "일부 카테고리만 조용히 빠짐" 이 "완료." 로 보고될
# 수 있었다(재현 확인, fix 보고서 참고).
#
# 고친 방법: 스크립트 맨 앞에서 딱 한 번, 이후 필요한 모든 키 경로의 존재/타입을
# node 에서 전부 검증하고, 그 결과를 일반 커맨드 치환(`$(...)`, 프로세스 치환이
# 아님)으로 캡처해 종료코드를 직접 확인한다 — `set -e` 가 정상적으로 관찰하는
# 형태다. 검증을 통과한 뒤에는 이 텍스트 블롭을 awk 로 잘라 쓴다 — 이 시점부터는
# node 를 다시 호출하지 않으므로, "manifest 파싱이 조용히 실패해서 빈 목록으로
# 보이는" 경로 자체가 없다.
MANIFEST_LOADER='
const path = process.argv[1];
let m;
try {
  m = require(path);
} catch (e) {
  console.error("manifest.json 을 읽거나 파싱하는 데 실패했다: " + e.message);
  process.exit(1);
}
function fail(msg) {
  console.error("manifest.json 검증 실패: " + msg);
  process.exit(1);
}
function assertStringArray(value, label) {
  if (!Array.isArray(value)) fail(label + " 이(가) 배열이 아니다.");
  value.forEach((x, i) => {
    if (typeof x !== "string" || x.length === 0) {
      fail(label + "[" + i + "] 이(가) 비어있지 않은 문자열이 아니다.");
    }
  });
}
if (typeof m !== "object" || m === null) fail("최상위 값이 객체가 아니다.");
if (typeof m.plugins !== "object" || m.plugins === null) fail("plugins 키가 없다.");
assertStringArray(m.plugins.remove, "plugins.remove");
assertStringArray(m.plugins.keep, "plugins.keep");
if (typeof m.marketplaces !== "object" || m.marketplaces === null) fail("marketplaces 키가 없다.");
assertStringArray(m.marketplaces.remove, "marketplaces.remove");
if (!Array.isArray(m.marketplaces.keep)) fail("marketplaces.keep 이(가) 배열이 아니다.");
m.marketplaces.keep.forEach((x, i) => {
  if (typeof x !== "object" || x === null) fail("marketplaces.keep[" + i + "] 이(가) 객체가 아니다.");
  if (typeof x.name !== "string" || !x.name) fail("marketplaces.keep[" + i + "].name 이 비어있다.");
  if (typeof x.source !== "string" || !x.source) fail("marketplaces.keep[" + i + "].source 가 비어있다.");
});
if (typeof m.mcpServers !== "object" || m.mcpServers === null) fail("mcpServers 키가 없다.");
if (typeof m.mcpServers.userScope !== "object" || m.mcpServers.userScope === null) fail("mcpServers.userScope 키가 없다.");
assertStringArray(m.mcpServers.userScope.remove, "mcpServers.userScope.remove");

const lines = [];
for (const x of m.plugins.remove) lines.push("PR\t" + x);
for (const x of m.plugins.keep) lines.push("PK\t" + x);
for (const x of m.marketplaces.remove) lines.push("MR\t" + x);
for (const x of m.marketplaces.keep) lines.push("MK\t" + x.name + "\t" + x.source);
for (const x of m.mcpServers.userScope.remove) lines.push("MU\t" + x);
process.stdout.write(lines.join("\n"));
'

set +e
MANIFEST_DATA="$(node -e "$MANIFEST_LOADER" -- "$MANIFEST" 2>&1)"
MANIFEST_STATUS=$?
set -e
if [ "$MANIFEST_STATUS" -ne 0 ]; then
  echo "오류: manifest.json 로드/검증에 실패했다. 아무 작업도 하지 않고 중단한다." >&2
  printf '%s\n' "$MANIFEST_DATA" >&2
  exit 1
fi

# 이미 검증된 MANIFEST_DATA 를 태그(PR/PK/MR/MK/MU)로 걸러서 목록을 뽑는다. 이
# 시점부터는 node 를 다시 부르지 않는다 — awk 는 이미 유효하다고 확인된 텍스트를
# 자르는 것뿐이라 새로운 "조용히 실패" 경로를 만들지 않는다.
manifest_field() {
  printf '%s\n' "$MANIFEST_DATA" | awk -F'\t' -v t="$1" '$1==t{print $2}'
}
manifest_pairs() {
  printf '%s\n' "$MANIFEST_DATA" | awk -F'\t' -v t="$1" '$1==t{print $2"\t"$3}'
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

echo "── 1/3 install ──"
# Important(round 3): 원래는 purge 를 먼저 하고 install 을 나중에 했다. 그 사이에
# 프로세스가 죽으면(Ctrl-C, 터미널 종료, OOM) trap 도 경고도 없이 "옛 것은 이미
# 지워졌고 새 것은 아직 안 깔린" 상태로 남는다. install 대상(keep 목록)과 purge
# 대상(remove 목록)은 서로 겹치지 않는다 — bootstrap.test.mjs 의 "keep 과 remove 에
# 같은 항목이 동시에 있으면 안 된다" 테스트로 이미 보장돼 있다. 그래서 두 단계는
# 충돌하지 않고, install 을 먼저 하면 중간에 죽어도 "새 것 + 옛 것" 이 남아
# "아무것도 없음" 보다 안전하다 — 그래서 순서를 install → purge 로 바꿨다.
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
done < <(manifest_pairs MK)
while IFS= read -r p; do [ -n "$p" ] && ensure_present plugin_installed "$p" claude plugin install "$p"; done < <(manifest_field PK)

echo "── 2/3 purge ──"
while IFS= read -r p; do [ -n "$p" ] && ensure_absent plugin_installed "$p" claude plugin uninstall "$p"; done < <(manifest_field PR)
while IFS= read -r mk; do [ -n "$mk" ] && ensure_absent marketplace_configured "$mk" claude plugin marketplace remove "$mk"; done < <(manifest_field MR)
while IFS= read -r s; do [ -n "$s" ] && ensure_absent mcp_in_user_scope "$s" claude mcp remove "$s" -s user; done < <(manifest_field MU)
run_required node "$ROOT/bootstrap/strip-hooks.mjs"

echo "── 3/3 project scope ──"
echo "프로젝트 스코프 MCP 는 각 레포 자체의 .mcp.json 에 커밋되어 있다. 레포를 clone 하면 설정이 함께 따라오므로 별도 수동 배치가 필요 없다."

if [ "$FAILURES" -gt 0 ]; then
  echo "실패: ${FAILURES}건 — 위 [실패] 로그를 확인할 것. claude plugin list / claude mcp list 로 실제 상태를 점검하라." >&2
  exit 1
fi
echo "완료. 확인: claude plugin list / claude mcp list"

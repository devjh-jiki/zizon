#!/usr/bin/env bash
# bootstrap.sh 의 ensure_absent/ensure_present 실패 판정 로직을 스텁 claude 로 검증한다.
#
# 배경: round 1 리뷰에서 지적된 Critical(문구 추정 오분류)을 상태 재조회 방식으로
# 고쳤는데, round 2 리뷰가 재조회 자체가 실패하는 경우("~/.claude.json 손상" 같은)를
# 놓친다고 다시 지적했다 — present(0)/absent(1)/unknown(2) 세 상태를 종료코드로 구분하고
# unknown 을 실패로 처리하도록 고쳤다. 이 스크립트는 그 세 갈래를 실제 bootstrap.sh 를
# (스텁 claude 위에서) 끝까지 실행해 검증한다:
#   1) 커맨드 실패 + 재조회도 실패(unknown)  → FAILURES 증가, 스크립트 exit != 0
#   2) 커맨드 실패 + 재조회가 "부재" 확인     → 무해, FAILURES 그대로, exit 0
#   3) 커맨드가 애초에 성공                   → 무해, FAILURES 그대로, exit 0
#   (덤) 커맨드 실패 + 재조회가 "여전히 존재" 확인 → FAILURES 증가, exit != 0
#
# 스텁 claude 는 실제 claude 바이너리를 절대 호출하지 않는다 — PATH 맨 앞에 가짜
# claude 실행파일을 두고, 매니페스트도 이 테스트 전용 임시 파일을 쓴다. 실제 사용자
# 환경/설치는 전혀 건드리지 않는다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_SH="$ROOT/bootstrap/bootstrap.sh"
STRIP_HOOKS="$ROOT/bootstrap/strip-hooks.mjs"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

FAIL=0
assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if ! printf '%s' "$haystack" | grep -qF -- "$needle"; then
    echo "FAIL: $label — 출력에 '$needle' 이(가) 없음" >&2
    echo "---- 실제 출력 ----" >&2
    printf '%s\n' "$haystack" >&2
    echo "-------------------" >&2
    FAIL=1
  fi
}
assert_exit() {
  local actual="$1" expected="$2" label="$3"
  if [ "$actual" -ne "$expected" ]; then
    echo "FAIL: $label — exit=$actual (기대값 $expected)" >&2
    FAIL=1
  fi
}

# 테스트용 가짜 $HOME — strip-hooks.mjs 가 실행되긴 하지만 hooks 가 없는 빈
# settings.json 을 보게 해서 "훅 없음 — 건너뜀" 으로 조용히 성공하게 한다
# (이 테스트가 검증하려는 신호와 섞이지 않도록).
FAKE_HOME="$WORKDIR/home"
mkdir -p "$FAKE_HOME/.claude"
echo '{}' > "$FAKE_HOME/.claude/settings.json"

# bootstrap.sh 가 자기 위치 기준 상대경로로 manifest/strip-hooks 를 찾으므로,
# 실제 스크립트를 그대로(수정 없이) 임시 bootstrap/ 레이아웃에 복사해 사용한다.
run_case() {
  local case_name="$1" manifest_json="$2" claude_stub="$3"
  local case_dir="$WORKDIR/$case_name"
  mkdir -p "$case_dir/bootstrap"
  cp "$BOOTSTRAP_SH" "$case_dir/bootstrap/bootstrap.sh"
  cp "$STRIP_HOOKS" "$case_dir/bootstrap/strip-hooks.mjs"
  printf '%s' "$manifest_json" > "$case_dir/bootstrap/manifest.json"

  local bin_dir="$case_dir/bin"
  mkdir -p "$bin_dir"
  printf '%s' "$claude_stub" > "$bin_dir/claude"
  chmod +x "$bin_dir/claude"

  local out status
  set +e
  out="$(HOME="$FAKE_HOME" PATH="$bin_dir:$PATH" bash "$case_dir/bootstrap/bootstrap.sh" 2>&1)"
  status=$?
  set -e
  printf '%s\x1e%s' "$out" "$status"
}

# ── 케이스 1: 커맨드 실패, 재조회(plugin list)도 실패 → unknown → 진짜 실패 ──
manifest_unknown='{
  "marketplaces": { "keep": [], "remove": [] },
  "plugins": { "keep": [], "remove": ["mystery-plugin@mystery"] },
  "mcpServers": { "userScope": { "remove": [] } },
  "projectScoped": {},
  "settings": { "removeHooks": { "reason": "test", "matchCommand": "agentmemory" } }
}'
stub_unknown='#!/usr/bin/env bash
case "$1" in
  --version) exit 0 ;;
  plugin)
    case "$2" in
      uninstall) echo "boom" >&2; exit 1 ;;
      list) echo "설정 파일이 손상되어 조회 실패" >&2; exit 1 ;;
      marketplace) exit 0 ;;
      install) exit 0 ;;
    esac ;;
  mcp) exit 0 ;;
esac
exit 1
'
result="$(run_case case1_unknown "$manifest_unknown" "$stub_unknown")"
out1="${result%$'\x1e'*}"; status1="${result##*$'\x1e'}"
assert_exit "$status1" 1 "케이스1(unknown): 스크립트 exit code"
assert_contains "$out1" "[실패]" "케이스1(unknown): 실패 로그 출력"
assert_contains "$out1" "unknown" "케이스1(unknown): unknown 사유 명시"
assert_contains "$out1" "실패: 1건" "케이스1(unknown): FAILURES 카운트 1"

# ── 케이스 2: 커맨드 실패, 재조회가 "여전히 존재" 확인 → 진짜 실패 ──
manifest_stillpresent='{
  "marketplaces": { "keep": [], "remove": [] },
  "plugins": { "keep": [], "remove": ["stuck-plugin@stuck"] },
  "mcpServers": { "userScope": { "remove": [] } },
  "projectScoped": {},
  "settings": { "removeHooks": { "reason": "test", "matchCommand": "agentmemory" } }
}'
stub_stillpresent='#!/usr/bin/env bash
case "$1" in
  --version) exit 0 ;;
  plugin)
    case "$2" in
      uninstall) echo "boom" >&2; exit 1 ;;
      list) printf "Installed plugins:\n\n  %s stuck-plugin@stuck\n" "❯"; exit 0 ;;
      marketplace) exit 0 ;;
      install) exit 0 ;;
    esac ;;
  mcp) exit 0 ;;
esac
exit 1
'
result="$(run_case case2_stillpresent "$manifest_stillpresent" "$stub_stillpresent")"
out2="${result%$'\x1e'*}"; status2="${result##*$'\x1e'}"
assert_exit "$status2" 1 "케이스2(여전히 존재): 스크립트 exit code"
assert_contains "$out2" "[실패]" "케이스2(여전히 존재): 실패 로그 출력"
assert_contains "$out2" "여전히 존재함" "케이스2(여전히 존재): 사유 명시"
assert_contains "$out2" "실패: 1건" "케이스2(여전히 존재): FAILURES 카운트 1"

# ── 케이스 3: 커맨드 실패했지만 재조회가 "부재" 확인 → 무해 / 케이스 4: 커맨드가
# 애초에 바로 성공 → 무해. 한 매니페스트에 두 항목을 같이 넣어 한 번에 검증한다.
manifest_benign='{
  "marketplaces": { "keep": [], "remove": [] },
  "plugins": { "keep": [], "remove": ["easy-plugin@easy", "gone-plugin@gone"] },
  "mcpServers": { "userScope": { "remove": [] } },
  "projectScoped": {},
  "settings": { "removeHooks": { "reason": "test", "matchCommand": "agentmemory" } }
}'
stub_benign='#!/usr/bin/env bash
case "$1" in
  --version) exit 0 ;;
  plugin)
    case "$2" in
      uninstall)
        case "$3" in
          easy-plugin@easy) exit 0 ;;
          gone-plugin@gone) echo "Error: plugin not found" >&2; exit 1 ;;
          *) exit 1 ;;
        esac ;;
      list) printf "No plugins installed.\n"; exit 0 ;;
      marketplace) exit 0 ;;
      install) exit 0 ;;
    esac ;;
  mcp) exit 0 ;;
esac
exit 1
'
result="$(run_case case3_benign "$manifest_benign" "$stub_benign")"
out3="${result%$'\x1e'*}"; status3="${result##*$'\x1e'}"
assert_exit "$status3" 0 "케이스3/4(무해): 스크립트 exit code"
assert_contains "$out3" "→ claude plugin uninstall easy-plugin@easy" "케이스4(즉시 성공): 커맨드 실행 로그"
assert_contains "$out3" "재조회 결과 이미 부재함" "케이스3(부재 확인): 무해 판정 로그"
assert_contains "$out3" "완료." "케이스3/4(무해): 최종 완료 메시지"
if printf '%s' "$out3" | grep -q '\[실패\]'; then
  echo "FAIL: 케이스3/4(무해) — [실패] 로그가 나오면 안 되는데 나옴" >&2
  FAIL=1
fi

# ── 사전가드: claude 가 PATH 에 아예 없으면 아무 것도 하지 않고 즉시 중단 ──
case_dir="$WORKDIR/case5_noclaude"
mkdir -p "$case_dir/bootstrap"
cp "$BOOTSTRAP_SH" "$case_dir/bootstrap/bootstrap.sh"
cp "$STRIP_HOOKS" "$case_dir/bootstrap/strip-hooks.mjs"
printf '%s' "$manifest_benign" > "$case_dir/bootstrap/manifest.json"
set +e
out5="$(HOME="$FAKE_HOME" PATH="/usr/bin:/bin" bash "$case_dir/bootstrap/bootstrap.sh" --dry-run 2>&1)"
status5=$?
set -e
assert_exit "$status5" 1 "케이스5(claude 없음): 스크립트 exit code"
assert_contains "$out5" "claude 명령을 PATH 에서 찾을 수 없다" "케이스5(claude 없음): 사전가드 메시지"
if printf '%s' "$out5" | grep -q '완료'; then
  echo "FAIL: 케이스5(claude 없음) — 완료 를 출력하면 안 되는데 나옴" >&2
  FAIL=1
fi

if [ "$FAIL" -ne 0 ]; then
  echo "bootstrap-helpers.test.sh: 실패" >&2
  exit 1
fi
echo "bootstrap-helpers.test.sh: 5개 케이스 모두 통과"

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
# round 3 리뷰는 세 번째 문(process substitution 이 manifest 로딩 실패를 삼키는 것)을
# 잡아냈다 — 케이스 6~8 이 그걸 검증한다:
#   6) manifest.json 이 깨진 JSON             → 계획을 하나도 안 찍고 즉시 exit != 0
#   7) 유효한 JSON 이지만 의존 키가 리네임됨   → 위와 동일(리뷰어의 Case B 재현)
#   8) 정상 manifest (대조군)                 → 가드가 과민하지 않고 평소대로 동작
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
  local case_name="$1" manifest_json="$2" claude_stub="$3"; shift 3
  # 나머지 인자는 bootstrap.sh 에 그대로 넘기는 플래그(예: --dry-run).
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
  out="$(HOME="$FAKE_HOME" PATH="$bin_dir:$PATH" bash "$case_dir/bootstrap/bootstrap.sh" "$@" 2>&1)"
  status=$?
  set -e
  printf '%s\x1e%s' "$out" "$status"
}

# --version 만 답하는 최소 스텁 — manifest 검증 단계에서 멈추는 케이스는 claude 가
# 그 이후로 호출되지 않으므로 이거면 충분하다.
stub_version_only='#!/usr/bin/env bash
case "$1" in
  --version) exit 0 ;;
esac
exit 1
'

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

# ── 케이스 6~8 (round 3): manifest 로딩 자체가 실패하는 경로 ──────────────
# round 3 리뷰가 잡아낸 버그: jq_list/jq_pairs 를 `< <(node -e ...)` (프로세스 치환)
# 안에서 호출했었다. node 가 manifest 파싱/키 검증에서 예외로 죽으면 stdout 없이
# exit != 0 인데, 프로세스 치환 서브셸의 종료코드는 `set -e` 가 관찰하지 못해서
# `while read` 가 그냥 0번 순회하고 넘어갔다 — FAILURES 증가 없이 "완료." 출력.
# 지금은 manifest 를 스크립트 맨 앞에서 일반 커맨드 치환으로 한 번만 로드·검증하고
# 종료코드를 직접 확인하므로, 아래 두 케이스는 어떤 [dry-run] 계획도 찍기 전에
# 즉시 중단해야 한다. 전부 --dry-run 으로 재현한다(실제 커맨드 실행 없음).

# 케이스 6: manifest.json 자체가 깨진 JSON.
result="$(run_case case6_malformed_json '{not valid json' "$stub_version_only" --dry-run)"
out6="${result%$'\x1e'*}"; status6="${result##*$'\x1e'}"
assert_exit "$status6" 1 "케이스6(깨진 JSON): 스크립트 exit code"
assert_contains "$out6" "manifest.json 을 읽거나 파싱하는 데 실패했다" "케이스6(깨진 JSON): 로드 실패 메시지"
if printf '%s' "$out6" | grep -q '완료'; then
  echo "FAIL: 케이스6(깨진 JSON) — 완료 를 출력하면 안 되는데 나옴" >&2
  FAIL=1
fi
if printf '%s' "$out6" | grep -q '\[dry-run\]'; then
  echo "FAIL: 케이스6(깨진 JSON) — 계획을 하나라도 찍으면 안 되는데 찍음(검증보다 먼저 실행됨)" >&2
  FAIL=1
fi

# 케이스 7: 유효한 JSON 이지만 스크립트가 의존하는 키 경로가 리네임돼 사라짐
# (plugins.remove → plugins.uninstall, 리뷰어의 Case B 재현).
manifest_renamed_key='{
  "marketplaces": { "keep": [], "remove": [] },
  "plugins": { "keep": [], "uninstall": ["ghost-plugin@ghost"] },
  "mcpServers": { "userScope": { "remove": [] } },
  "projectScoped": {},
  "settings": { "removeHooks": { "reason": "test", "matchCommand": "agentmemory" } }
}'
result="$(run_case case7_renamed_key "$manifest_renamed_key" "$stub_version_only" --dry-run)"
out7="${result%$'\x1e'*}"; status7="${result##*$'\x1e'}"
assert_exit "$status7" 1 "케이스7(키 리네임): 스크립트 exit code"
assert_contains "$out7" "plugins.remove" "케이스7(키 리네임): 어떤 키가 문제인지 명시"
if printf '%s' "$out7" | grep -q '완료'; then
  echo "FAIL: 케이스7(키 리네임) — 완료 를 출력하면 안 되는데 나옴" >&2
  FAIL=1
fi
if printf '%s' "$out7" | grep -q '\[dry-run\]'; then
  echo "FAIL: 케이스7(키 리네임) — 마켓플레이스/MCP 제거 등 다른 카테고리 계획이 조용히 찍히면 안 되는데 찍음" >&2
  FAIL=1
fi

# 케이스 8: 위 두 케이스와 대조군 — 정상적인(다섯 키 경로 모두 온전한) manifest 는
# 가드에 걸리지 않고 평소대로 계획을 출력해야 한다("과민 반응 아님"을 증명).
result="$(run_case case8_wellformed "$manifest_benign" "$stub_version_only" --dry-run)"
out8="${result%$'\x1e'*}"; status8="${result##*$'\x1e'}"
assert_exit "$status8" 0 "케이스8(정상 manifest): 스크립트 exit code"
assert_contains "$out8" "[dry-run] claude plugin uninstall easy-plugin@easy" "케이스8(정상 manifest): 계획이 정상 출력됨"
assert_contains "$out8" "완료." "케이스8(정상 manifest): 최종 완료 메시지"
if printf '%s' "$out8" | grep -q '검증 실패\|로드/검증에 실패'; then
  echo "FAIL: 케이스8(정상 manifest) — 정상 manifest 인데 검증 실패로 오판함" >&2
  FAIL=1
fi

if [ "$FAIL" -ne 0 ]; then
  echo "bootstrap-helpers.test.sh: 실패" >&2
  exit 1
fi
echo "bootstrap-helpers.test.sh: 8개 케이스 모두 통과"

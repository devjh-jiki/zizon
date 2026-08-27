import { readFile, writeFile, copyFile, rename } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

// 무엇을 지울지는 하드코딩하지 않는다 — bootstrap/manifest.json 의
// settings.removeHooks.matchCommand 가 유일한 출처다. 예전엔 이 스크립트가
// 'agentmemory' 를 직접 문자열로 박아 매니페스트가 선언한 값과 무관하게
// 동작했다(매니페스트를 바꿔도 아무 효과가 없는 죽은 설정). manifest.json 은
// 이 파일과 같은 bootstrap/ 디렉터리에 있다.
const scriptDir = dirname(fileURLToPath(import.meta.url));
const manifestPath = join(scriptDir, 'manifest.json');
const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
const matchCommand = manifest?.settings?.removeHooks?.matchCommand;
if (typeof matchCommand !== 'string' || !matchCommand) {
  console.error(`오류: ${manifestPath} 의 settings.removeHooks.matchCommand 가 비어있거나 문자열이 아니다.`);
  process.exit(1);
}

// agentmemory 플러그인이 hooks/hooks.json 을 ${CLAUDE_PLUGIN_ROOT} 로 이미 등록한다
// (SessionStart/UserPromptSubmit/PreToolUse/PreCompact/Stop/SessionEnd 6개 이벤트,
//  settings.json 의 절대경로 사본과 커맨드가 동일 — 실측 확인됨).
// 이 스크립트는 그 settings.json 사본만 제거한다. 플러그인 쪽 훅은 건드리지 않는다.
const p = join(homedir(), '.claude/settings.json');
const s = JSON.parse(await readFile(p, 'utf8'));
if (!s.hooks) {
  console.log('훅 없음 — 건너뜀');
  process.exit(0);
}

let removed = 0;
const next = {};
for (const [event, entries] of Object.entries(s.hooks)) {
  const kept = entries.filter(
    (entry) => !(entry.hooks ?? []).some((h) => (h.command ?? '').includes(matchCommand)),
  );
  removed += entries.length - kept.length;
  if (kept.length) next[event] = kept;
}

if (removed === 0) {
  // 이미 정리된 상태 — 파일을 건드리지 않는다 (재실행 시 .bak 를 덮어쓰지 않기 위함이기도 하다).
  console.log('agentmemory 훅 없음 — 이미 정리된 상태, 변경 없음');
  process.exit(0);
}

s.hooks = next;
if (!Object.keys(s.hooks).length) delete s.hooks;

await copyFile(p, `${p}.bak`);
// writeFile(p, ...) 는 기존 파일을 잘라내고(truncate) 다시 쓰므로, 쓰는 도중 죽으면
// (OOM, 디스크 풀, SIGKILL) settings.json 이 반쪽짜리 상태로 남을 수 있다. 같은
// 파일시스템의 임시 파일에 먼저 쓰고 rename 으로 교체한다 — rename 은 원자적이라
// 결과는 항상 "이전 내용 그대로" 아니면 "새 내용 전체" 둘 중 하나다.
const tmp = `${p}.tmp`;
await writeFile(tmp, JSON.stringify(s, null, 2) + '\n');
await rename(tmp, p);
console.log(`"${matchCommand}" 중복 훅 ${removed}개 제거 (백업: ${p}.bak)`);

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

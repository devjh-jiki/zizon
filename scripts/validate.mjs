import { readdir, readFile, stat } from 'node:fs/promises';
import { join } from 'node:path';

export const BUCKETS = ['token', 'design', 'planning', 'review', 'testing', 'learning', 'util'];

function parseFrontmatter(text) {
  const m = text.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return null;
  const out = {};
  for (const line of m[1].split('\n')) {
    const kv = line.match(/^([a-zA-Z_-]+):\s*(.*)$/);
    if (kv) out[kv[1]] = kv[2].trim();
  }
  return out;
}

async function listDirs(path) {
  try {
    const entries = await readdir(path, { withFileTypes: true });
    return entries.filter((e) => e.isDirectory()).map((e) => e.name);
  } catch {
    return [];
  }
}

export async function validateSkills(root) {
  const errors = [];
  const skillsRoot = join(root, 'skills');
  for (const bucket of await listDirs(skillsRoot)) {
    if (!BUCKETS.includes(bucket)) {
      errors.push(`허용되지 않은 버킷: skills/${bucket} (허용: ${BUCKETS.join(', ')})`);
      continue;
    }
    for (const name of await listDirs(join(skillsRoot, bucket))) {
      const file = join(skillsRoot, bucket, name, 'SKILL.md');
      try {
        await stat(file);
      } catch {
        errors.push(`SKILL.md 없음: skills/${bucket}/${name}`);
        continue;
      }
      const fm = parseFrontmatter(await readFile(file, 'utf8'));
      if (!fm) {
        errors.push(`frontmatter 없음: skills/${bucket}/${name}/SKILL.md`);
        continue;
      }
      if (!fm.description) errors.push(`description 없음: skills/${bucket}/${name}/SKILL.md`);
      if (!fm.name) errors.push(`name 없음: skills/${bucket}/${name}/SKILL.md`);
      else if (fm.name !== name) errors.push(`name 불일치: skills/${bucket}/${name} 의 name 이 "${fm.name}"`);
      else if (!/^[a-z0-9-]+$/.test(fm.name)) errors.push(`name 형식 위반: ${fm.name} (소문자·숫자·하이픈만)`);
    }
  }
  return { errors };
}

export async function validateMarketplace(root, manifestPath) {
  const errors = [];
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  for (const plugin of manifest.plugins ?? []) {
    for (const rel of plugin.skills ?? []) {
      if (rel.endsWith('/')) {
        // 디렉토리 형식('./skills/') — 하위에 SKILL.md 가 하나라도 있어야 한다
        const dir = join(root, rel);
        const found = [];
        for (const bucket of await listDirs(dir)) {
          for (const name of await listDirs(join(dir, bucket))) {
            try { await stat(join(dir, bucket, name, 'SKILL.md')); found.push(name); } catch {}
          }
        }
        if (!found.length) errors.push(`marketplace 디렉토리에 스킬이 없음: ${rel} (${plugin.name})`);
        continue;
      }
      try {
        await stat(join(root, rel, 'SKILL.md'));
      } catch {
        errors.push(`marketplace 가 없는 스킬을 가리킴: ${rel} (${plugin.name})`);
      }
    }
  }
  return { errors };
}

// plugin.json 의 skills 가 개별 경로 나열 형식(디렉토리형 "./skills/" 가 zizon 의
// 중첩 버킷 구조를 스캔하지 못해 round 2 에서 19개 경로 나열로 바꿨다)일 때, 그
// 목록과 디스크의 실제 skills/<bucket>/<name>/ 을 서로 대조한다. 어느 쪽도 이걸
// 검사하지 않으면 스킬을 추가/삭제하고 plugin.json 갱신을 잊어도 아무 에러 없이
// 조용히 드리프트한다 — 이 태스크에서 나온 다섯 개 버그가 전부 "아무도 재확인하지
// 않는 계층"에서 나왔다는 지적에 따라 추가.
export async function validatePluginSkills(root, pluginPath) {
  const errors = [];
  const plugin = JSON.parse(await readFile(pluginPath, 'utf8'));
  const listed = plugin.skills ?? [];

  // 디렉토리 형식("./skills/" 같이 '/'로 끝나는 항목)이면 그 아래 전부를
  // 포괄하는 것으로 보고 대조를 건너뛴다 — 매니페스트 형식이 나중에 다시
  // 디렉토리형으로 바뀌어도 이 검사가 오탐으로 깨지지 않게 한다.
  if (listed.some((rel) => rel.endsWith('/'))) {
    return { errors };
  }

  const listedSet = new Set();
  for (const rel of listed) {
    listedSet.add(rel.replace(/^\.\//, '').replace(/\/$/, ''));
    try {
      await stat(join(root, rel, 'SKILL.md'));
    } catch {
      errors.push(`plugin.json 에 나열됐지만 디스크에 없음: ${rel}`);
    }
  }

  const skillsRoot = join(root, 'skills');
  for (const bucket of await listDirs(skillsRoot)) {
    for (const name of await listDirs(join(skillsRoot, bucket))) {
      try {
        await stat(join(skillsRoot, bucket, name, 'SKILL.md'));
      } catch {
        continue; // SKILL.md 부재는 validateSkills 가 이미 잡는다
      }
      const rel = `skills/${bucket}/${name}`;
      if (!listedSet.has(rel)) {
        errors.push(`디스크에 있지만 plugin.json 에 없음: ${rel}`);
      }
    }
  }

  return { errors };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const root = process.cwd();
  const a = await validateSkills(root);
  const b = await validateMarketplace(root, join(root, '.claude-plugin/marketplace.json'));
  const c = await validatePluginSkills(root, join(root, '.claude-plugin/plugin.json'));
  const errors = [...a.errors, ...b.errors, ...c.errors];
  if (errors.length) {
    for (const e of errors) console.error(`✗ ${e}`);
    process.exit(1);
  }
  console.log('✓ 스킬·마켓플레이스 검증 통과');
}

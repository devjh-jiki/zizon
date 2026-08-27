import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { validateSkills, validateMarketplace, validatePluginSkills, validateMarketplaceNoComponents } from './validate.mjs';

async function fixture(skills) {
  const root = await mkdtemp(join(tmpdir(), 'zizon-'));
  for (const [path, body] of Object.entries(skills)) {
    const dir = join(root, path);
    await mkdir(dir, { recursive: true });
    await writeFile(join(dir, 'SKILL.md'), body);
  }
  return root;
}

test('frontmatter 가 온전하면 에러가 없다', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\ndescription: Be terse.\n---\n본문',
  });
  const { errors } = await validateSkills(root);
  assert.deepEqual(errors, []);
});

test('name 이 디렉토리명과 다르면 에러', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: wrong-name\ndescription: Be terse.\n---\n본문',
  });
  const { errors } = await validateSkills(root);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /불일치/);
});

test('description 이 없으면 에러', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\n---\n본문',
  });
  const { errors } = await validateSkills(root);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /description/);
});

test('허용되지 않은 버킷은 에러', async () => {
  const root = await fixture({
    'skills/nonsense/foo': '---\nname: foo\ndescription: X.\n---\n본문',
  });
  const { errors } = await validateSkills(root);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /nonsense/);
});

test('SKILL.md 파일이 없으면 에러', async () => {
  const root = await fixture({
    'skills/token/missing-file': '---\nname: missing-file\ndescription: Test.\n---\n',
  });
  // fixture가 SKILL.md를 만들었으므로 삭제
  await rm(join(root, 'skills/token/missing-file/SKILL.md'));
  const { errors } = await validateSkills(root);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /SKILL.md 없음/);
});

test('frontmatter가 없으면 에러', async () => {
  const root = await fixture({
    'skills/token/no-frontmatter': 'name: foo\ndescription: X.\n본문',
  });
  const { errors } = await validateSkills(root);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /frontmatter 없음/);
});

test('name 형식이 잘못되면 에러', async () => {
  const root = await fixture({
    'skills/token/Bad_Name': '---\nname: Bad_Name\ndescription: X.\n---\n본문',
  });
  const { errors } = await validateSkills(root);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /형식 위반/);
});

test('marketplace 의 skills 경로가 실재하면 통과', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\ndescription: Be terse.\n---\n본문',
  });
  await writeFile(join(root, 'marketplace.json'), JSON.stringify({
    plugins: [{ name: 'zizon', skills: ['./skills/token/terse-output'] }],
  }));
  const { errors } = await validateMarketplace(root, join(root, 'marketplace.json'));
  assert.deepEqual(errors, []);
});

test('디렉토리 형식 ./skills/ 은 하위에 스킬이 있으면 통과', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\ndescription: Be terse.\n---\n본문',
  });
  await writeFile(join(root, 'marketplace.json'), JSON.stringify({
    plugins: [{ name: 'zizon', skills: ['./skills/'] }],
  }));
  const { errors } = await validateMarketplace(root, join(root, 'marketplace.json'));
  assert.deepEqual(errors, []);
});

test('디렉토리 형식인데 하위에 스킬이 없으면 에러', async () => {
  const root = await fixture({});
  await writeFile(join(root, 'marketplace.json'), JSON.stringify({
    plugins: [{ name: 'zizon', skills: ['./skills/'] }],
  }));
  const { errors } = await validateMarketplace(root, join(root, 'marketplace.json'));
  assert.equal(errors.length, 1);
  assert.match(errors[0], /스킬이 없음/);
});

test('marketplace 가 없는 스킬을 가리키면 에러', async () => {
  const root = await fixture({});
  await writeFile(join(root, 'marketplace.json'), JSON.stringify({
    plugins: [{ name: 'zizon', skills: ['./skills/token/ghost'] }],
  }));
  const { errors } = await validateMarketplace(root, join(root, 'marketplace.json'));
  assert.equal(errors.length, 1);
  assert.match(errors[0], /ghost/);
});

test('plugin.json 이 디스크와 정확히 일치하면 에러 없다', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\ndescription: Be terse.\n---\n본문',
    'skills/design/anti-slop-frontend': '---\nname: anti-slop-frontend\ndescription: X.\n---\n본문',
  });
  await writeFile(join(root, 'plugin.json'), JSON.stringify({
    skills: ['./skills/token/terse-output', './skills/design/anti-slop-frontend'],
  }));
  const { errors } = await validatePluginSkills(root, join(root, 'plugin.json'));
  assert.deepEqual(errors, []);
});

test('plugin.json 이 디스크에 없는 경로를 나열하면 에러', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\ndescription: Be terse.\n---\n본문',
  });
  await writeFile(join(root, 'plugin.json'), JSON.stringify({
    skills: ['./skills/token/terse-output', './skills/token/ghost'],
  }));
  const { errors } = await validatePluginSkills(root, join(root, 'plugin.json'));
  assert.equal(errors.length, 1);
  assert.match(errors[0], /ghost/);
});

test('디스크에 있는데 plugin.json 에 없는 스킬은 에러', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\ndescription: Be terse.\n---\n본문',
    'skills/design/anti-slop-frontend': '---\nname: anti-slop-frontend\ndescription: X.\n---\n본문',
  });
  await writeFile(join(root, 'plugin.json'), JSON.stringify({
    skills: ['./skills/token/terse-output'],
  }));
  const { errors } = await validatePluginSkills(root, join(root, 'plugin.json'));
  assert.equal(errors.length, 1);
  assert.match(errors[0], /anti-slop-frontend/);
});

test('plugin.json 이 디렉토리 형식이면 내용과 무관하게 에러 없다', async () => {
  const root = await fixture({
    'skills/token/terse-output': '---\nname: terse-output\ndescription: Be terse.\n---\n본문',
  });
  await writeFile(join(root, 'plugin.json'), JSON.stringify({
    skills: ['./skills/'],
  }));
  const { errors } = await validatePluginSkills(root, join(root, 'plugin.json'));
  assert.deepEqual(errors, []);
});

test('marketplace.json 의 plugin 항목이 skills 를 선언하면 에러 (manifest 충돌)', async () => {
  const root = await fixture({});
  await writeFile(join(root, 'marketplace.json'), JSON.stringify({
    plugins: [{ name: 'zizon', source: './', skills: ['./skills/token/terse-output'] }],
  }));
  const { errors } = await validateMarketplaceNoComponents(join(root, 'marketplace.json'));
  assert.equal(errors.length, 1);
  assert.match(errors[0], /zizon/);
  assert.match(errors[0], /skills/);
});

test('marketplace.json 의 plugin 항목이 mcpServers/hooks 등 다른 컴포넌트 키를 선언해도 에러', async () => {
  const root = await fixture({});
  await writeFile(join(root, 'marketplace.json'), JSON.stringify({
    plugins: [{ name: 'zizon', source: './', mcpServers: {}, hooks: {} }],
  }));
  const { errors } = await validateMarketplaceNoComponents(join(root, 'marketplace.json'));
  assert.equal(errors.length, 2);
});

test('marketplace.json 의 plugin 항목에 컴포넌트 키가 없으면 통과', async () => {
  const root = await fixture({});
  await writeFile(join(root, 'marketplace.json'), JSON.stringify({
    plugins: [{ name: 'zizon', source: './', version: '0.2.0', strict: false }],
  }));
  const { errors } = await validateMarketplaceNoComponents(join(root, 'marketplace.json'));
  assert.deepEqual(errors, []);
});

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { validateSkills, validateMarketplace } from './validate.mjs';

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

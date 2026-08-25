import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { validateSkills } from './validate.mjs';

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
  assert.match(errors[0], /terse-output/);
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

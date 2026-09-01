# Output Styles

> 한국어: [README.ko.md](./README.ko.md)

Skills in `skills/` are invoked on demand. An output style is always on while selected,
so it is the only mechanism that can reach the Korean in an ordinary one-line reply.

## Registered

- [fluent-korean](./fluent-korean.md) — keeps particles and verb endings intact and stops sentences
  from trailing off as bare noun phrases. Adapted from [snflkd/fluent-korean](https://github.com/snflkd/fluent-korean) (MIT).

## Enabling

This repo does not bump versions, so `plugin update` will not pick the change up. Reinstall:

```
claude plugin marketplace update zizon
claude plugin uninstall zizon@zizon && claude plugin install zizon@zizon
```

Then name it directly in `~/.claude/settings.json`. It is **`zizon:fluent-korean`, not `fluent-korean`**:
Claude Code keys a plugin-supplied style as `${plugin}:${frontmatter name}`.

```json
{ "outputStyle": "zizon:fluent-korean" }
```

Start a new session afterwards; styles are read at startup. Remove the key to revert.

While iterating, `./bootstrap/bootstrap.sh --dev` points the install at local source without a push.

### Verified on 2.1.236

Without this section the next person gets stuck in the same three places. Three people did.

- **There is no `/output-style` slash command.** It is a field inside `/config`.
- **The `/config` dropdown lists built-in styles only** (`options: Object.keys(xke)`, where `xke` holds
  the built-ins). Custom styles can only be selected through the settings file.
- **The name carries a plugin prefix.** `sDp` in the bundle builds the key as `` `${t}:${l}` ``.
  An unprefixed name is silently ignored and the default style stays in effect.

Avoid the `~/.claude/output-styles/` user directory. The function that assembles the style list (`aDp`)
iterates only over enabled plugins' `outputStylesPath` and has no branch reading the user home.
That is read from the bundle, not confirmed empirically.

## Why this one is vendored

This repo's default is to not copy external plugins (see "외부 추천 플러그인" in the root README),
so that upstream updates and verification carry over.

fluent-korean is the exception because it **conflicts with assets already in this repo and cannot be
enabled without added clauses**. That is the copying rule: install upstream when nothing needs changing,
vendor it with attribution when it only works after a change.

Two conflicts. **Register**: the upstream target example under "구 단위 1" is maximally verbose 합쇼체,
while every skill here and every document in `vault` is terse 해라체. **Compression**: `token/terse-output`
and `token/i-have-adhd` tell the model to shorten sentences; upstream tells it to restore particles and endings.

## What changed

Three clauses appended to upstream's "동작 범위". No rule in the body was touched.
Upstream clause 2 already defers code-bound text to project convention, so these are its siblings.

| Clause | Effect |
|---|---|
| 5 | Text written to a file through Write/Edit follows that project's writing standard; if there is none, the body rules apply |
| 6 | A file-bound draft shown in chat is shown in its final form |
| 7 | An explicit request to compress output takes precedence |

The boundary is "text written to a file" vs "text spoken in chat", not "document" vs "reply",
because the first is decided by which tool is called and the second by a judgment call every time.

## When upstream changes

Registered in the matrix of `.github/workflows/sync-upstream-skills.yml`. Every Monday the workflow
snapshots upstream into `.upstream/snflkd-fluent-korean/` and commits only when something differs.
Its `path` is `plugins/fluent-korean/output-styles` rather than `skills`, since this is not a skill.

**Nothing is merged automatically**, matching this repo's existing policy. To see what moved:

```bash
diff .upstream/snflkd-fluent-korean/fluent-korean.md output-styles/fluent-korean.md
```

Clauses 5, 6 and 7 exist only on this side, so they always show as differences. Everything else in the
diff is a candidate to carry over. The fork baseline is commit `ce8683f` (2026-08-23), recorded in
`THIRD_PARTY_NOTICES.md`.

## Limits

Not a spellchecker: upstream has no orthography rules. Upstream's own README notes the effect
degrades over long tasks.

## Considered and declined

- [epoko77-ai/im-not-ai](https://github.com/epoko77-ai/im-not-ai) — post-hoc rewriting aimed at the
  column/essay genre, with 30%/50% change-rate gates. On terse 해라체 domain docs it flattens a deliberate voice.
- [DaleSeo/korean-skills](https://github.com/DaleSeo/korean-skills) — only `grammar-checker` touches the
  typo problem, and as a skill it cannot reach chat replies. Revisit if document orthography becomes a real problem.

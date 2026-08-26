---
name: resolving-merge-conflicts
description: Resolve an in-progress git merge or rebase conflict by recovering each side's intent and preserving both where possible. Use when the user has a conflicted merge/rebase, says "머지 충돌 해결", "리베이스 충돌", "conflict 났어", "fix this merge conflict", or git reports "CONFLICT (content)". For starting fresh branch work this isn't it; this is specifically for an already-conflicted tree.
---

# resolving-merge-conflicts

Resolve a conflict by understanding *why* each side changed the code, not by mechanically picking a hunk. Always resolve; never `--abort` and never `--skip` (both discard work).

## Steps

1. **See the current state.** Is this a merge or a rebase? Run `git status` and `git log --oneline --graph` and open the conflicting files. **Know which side is which** — in a `merge`, `HEAD`/`<<<<<<< ours` is your current branch and `theirs` is the incoming branch; in a `rebase` it's **inverted** — `HEAD` is the branch you're rebasing *onto*, and the `>>>>>>>` side is your own commit being replayed. Getting this backwards is the most common resolution error.

2. **Find the primary sources for each conflict.** Understand deeply why each change was made and the original intent — read the commit messages (`git log`/`git show` each side), the PRs, the issues. Diff each side against the merge base (`git merge-base`) so you see what each side actually changed, not just the final text.

3. **Resolve each hunk.** Preserve both intents where possible — before choosing, separate each change into *what it functionally does* vs *how it reads*; conflicts on style alone can often still compose (e.g. a phrasing change and an added decoration are orthogonal and both survive). Where genuinely incompatible, pick the side matching the merge's stated goal and note the trade-off; if no goal was stated, default to the least-lossy resolution and say so. Do **not** invent new behaviour — every surviving fragment should trace to one side.

4. **Run the project's automated checks.** Discover them and run in order — typically typecheck, then tests, then format — and fix anything the merge broke. If the repo has no checks configured, say so and fall back to a minimal smoke check (e.g. load/run the changed code once); don't fabricate a test suite.

5. **Finish the merge/rebase.** Stage everything and continue (`git commit` for a merge, `git rebase --continue` for a rebase) until all commits are replayed. `--continue` may open an editor for the commit message — in a non-interactive/agent context set `GIT_EDITOR=true` (or `--no-edit` where applicable) so it doesn't hang. Confirm with `git status` that no rebase/merge is in progress and the tree is clean.

## Owner / leadership lens

For a developer who is also CEO/CTO/CFO/PM, a conflict is two intents colliding — resolve the intents, not the text:

- **A blind hunk-pick silently deletes someone's work.** The cost of a bad resolution isn't the merge; it's the feature that vanished without anyone noticing until production. Recovering intent from commit messages is cheap insurance against that.
- **Record the trade-off when you drop a side.** "Kept X over Y because the merge targeted Z" in the commit message saves the next person from re-discovering the conflict — and from "fixing" your deliberate choice.
- **Never `--abort` to escape a hard conflict.** Aborting throws away the analysis you've already done; you'll just pay for it again. Push through to a resolution.

## Attribution

Adapted from [mattpocock/skills `resolving-merge-conflicts`](https://github.com/mattpocock/skills/tree/main/skills/engineering/resolving-merge-conflicts) (MIT). See THIRD_PARTY_NOTICES.md.

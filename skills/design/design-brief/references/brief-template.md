# Brief template

Write this to `design-brief.md`. Keep the section order. Every section earns its place;
none of them is optional.

```markdown
# <Project> design brief

As of <date the lookup ran>. Direction: <direction name>

## Situation read

<screen type> / <audience> / <vibe> / <quiet constraints>

## Chosen direction and why

<Why this one. Which axes it split from the other candidates on. What the deciding
factor was.>

## What would make this wrong

<The fact that, if true, kills this direction. Not a risk register: one or two things
that are actually checkable, each with what to switch to if it turns out true.>

## Tokens

Modes: <both / light only on purpose / dark only on purpose>. If only one, say why in
one line here; a reader who finds one column empty will otherwise assume it was forgotten.

| Role | Light | Dark | Contrast |
|---|---|---|---|
| Base | #xxxxxx | #xxxxxx | |
| Surface | #xxxxxx | #xxxxxx | |
| Text | #xxxxxx | #xxxxxx | x.x:1 on base, x.x:1 on surface |
| Muted text | #xxxxxx | #xxxxxx | x.x:1 on base, x.x:1 on surface |
| Divider | #xxxxxx | #xxxxxx | decorative |
| Control edge | #xxxxxx | #xxxxxx | x.x:1 on base, x.x:1 on surface |
| Accent | #xxxxxx | #xxxxxx | x.x:1 on base, x.x:1 as text |

| Setting | Value |
|---|---|
| Display face | <name> (<free or paid>, <on Google Fonts or not>) |
| Body face | <name>, or "same as display" |
| Layout variance | <1-10> |
| Motion intensity | <1-10> |
| Density | <1-10> |

Coolors: <url>

## References

- <url> <what this one is for>
- <url> <what this one is for>

## Rejected directions

| Direction | Why rejected |
|---|---|
| <name> | <reason> |
| <name> | <reason> |

## Not verified

<Fetches that failed, slugs that could not be confirmed, claims taken from a summarized
page rather than read directly. Write "none" only if that is true.>
```

## Why these sections exist

**"What would make this wrong" is not optional, and it is heaviest when the brief holds
one direction.** Step 4 attaches it to every candidate so the user can compare. When the
user hands the choice over and the three collapse to one, it becomes the only thing left
that lets them notice the answer does not fit their situation. Two independent
verification runs on 2026-09-02 reached that branch, found no section for it here, and
each invented one under a different name. A section the template omits is a section the
next brief will omit.

**All three dial rows are required.** Layout variance, motion intensity, and density map
one-to-one onto `anti-slop-frontend`'s DESIGN_VARIANCE, MOTION_INTENSITY, and
VISUAL_DENSITY. That skill skips its own situation read when this file exists, so a
missing row leaves its dial sitting on a default that nobody chose.

**Rejected directions.** Without it the next session proposes the same rejected direction
and the user rejects it again for the same reason. The reason is the reusable part, not
the name.

**Not verified.** The lookup step reads summarized pages, so some of what lands in the
brief is a lead rather than a fact. A brief that hides which is which invites someone to
build on the weakest line in it.

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

## Tokens

| Role | Light | Dark | Contrast |
|---|---|---|---|
| Base | #xxxxxx | #xxxxxx | |
| Surface | #xxxxxx | #xxxxxx | |
| Text | #xxxxxx | #xxxxxx | x.x:1 on base, x.x:1 on surface |
| Accent | #xxxxxx | #xxxxxx | x.x:1 on base |
| Border | #xxxxxx | #xxxxxx | x.x:1 on base |

| Setting | Value |
|---|---|
| Display face | <name> (<free or paid>) |
| Body face | <name> (<free or paid>) |
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

## Why the last two sections exist

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

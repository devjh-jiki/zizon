---
name: design-brief
description: >
  Turn a vague project brief into a grounded design direction before any UI code exists.
  Translates the project into real filter URLs on Awwwards and SaaSFrame, fetches what is
  currently there, then proposes three deliberately-distinct directions, each with real
  reference links, a WCAG-checked palette plus a Coolors URL, and a type pairing. Ends by
  writing a design brief file that implementation reads. Covers marketing surfaces and
  product UI (dashboards, onboarding, settings) alike. Use when the direction is not
  settled yet: starting a new UI, redesigning, choosing a palette or type from scratch, or
  when the user says "디자인 브레인스토밍", "레퍼런스 찾아줘", "색 조합 뽑아줘",
  "트렌드 보고 정하자", "design direction", "moodboard". NOT for tweaking colors in code
  that already has a direction, NOT for reviewing existing UI, and NOT for building a
  design system (tokens, component library). Such a system encodes a direction; this skill
  picks it. NOT a replacement for anti-slop-frontend, which implements what this picks.
---

# Design Brief

Decide the design direction from real references, not from adjectives, and leave the
decision in a file. Five steps. Do them in order.

The output is `design-brief.md` in the project. Implementation reads it instead of
re-deciding color and type on the fly.

**Scope:** any UI. Marketing surfaces and product UI (dashboards, onboarding, settings,
tables) alike. This runs *before* `anti-slop-frontend`, which implements what this picks.

## Step 1. Read the project

Pull five axes out of what the user said, plus the repo if one exists:

1. **Screen type.** Landing, pricing page, dashboard, onboarding flow, settings, docs, portfolio
2. **Audience.** B2B buying committee, design-literate consumer, clinician at work, recruiter scanning
3. **Vibe words.** Whatever they actually said: "minimal", "Linear-like", "editorial", "serious"
4. **Quiet constraints.** Accessibility-first, regulated industry, public sector, kids, safety-critical
5. **Existing brand assets.** Logo, colors, type, photography

**Quiet constraints override vibe preferences.** A clinician reading lab values at 2am
outranks "make it pop".

Emit one line and move on:

> Read as: `<screen type>` for `<audience>`, `<vibe>` language, under `<constraint>`.

## Step 2. Translate into search vocabulary

Turn that line into filter URLs the user can actually click. This is the step that does
the real work: "SaaS dashboard" becomes six openable links.

| Project signal | Site | Path |
|---|---|---|
| Aesthetic, motion, typography, layout | Awwwards tags | `/websites/<slug>/` |
| Industry or sector feel | Awwwards categories | `/websites/<slug>/` |
| Tech constraint already decided | Awwwards technologies | `/websites/<slug>/` |
| Screen type | SaaSFrame categories | `/categories/<slug>` |
| Section pattern | SaaSFrame patterns | `/patterns/<slug>` |

**The two sites are not parallel.** Awwwards is an awards corpus: marketing sites,
portfolios, experimental work. For product UI it contributes type, color, and motion
vocabulary and almost nothing about layout, so weight SaaSFrame for anything with a
sidebar and a data table. Verified on a dashboard run 2026-09-02, where the
`data-visualization` tag returned scroll-storytelling sites built on Three.js and GSAP.

Produce **two or three Awwwards URLs and two or three SaaSFrame URLs**. Not more. A wall
of links is the same as no links.

**Never invent a slug.** Confirmed slug lists live in `references/reference-sites.md`. If
you need an axis that is not on those lists, open the site's index page first and read the
real slug.

This matters more than it looks. **Awwwards does not 404 on an unknown slug.** It returns
200 and silently serves the unfiltered nominees list, verified 2026-09-02. So a guessed
slug hands you a page full of real results that has nothing to do with the filter you
thought you applied, and you go on to report a trend that does not exist. SaaSFrame does
return 404, so there the failure is loud.

Because that failure is silent, **the confirmed list is the guard, not a check performed
after the fact.** Use slugs from `references/reference-sites.md`. If you need one that is
not there, fetch the site's index page and read the real slug off it before you use it.

**A missing slug and a missing corpus are different problems, and only the first has an
escape hatch.** `brutalism` and `brutalist` are not Awwwards tags, and no industry
category covers finance. Verified 2026-09-02. Reading the index will not produce them,
because they are not there. When the aesthetic the user named is absent, do three things
and do not skip the first:

1. Tell the user the corpus cannot support that word. This is the honest half
2. Route around it with adjacent axes. `typography` and `colorful` carry part of what
   people mean by brutalism, and `app-style` carries part of what they mean by product UI
3. Mark in the brief that those links stand in for the aesthetic rather than demonstrate
   it

Step 4 asks for real reference URLs. Substitutes are legitimate, but only labeled as
substitutes.

Do not try to detect the fallback from the fetched page. The page-fetch tool summarizes
pages through a small model and does not reliably surface the `<title>` tag, which is the
only thing that distinguishes a live filter (`Best Minimal Websites`) from the fallback
(`Awwwards Nominees`). If you genuinely need to confirm one slug independently, read the
title with a shell command instead:

```sh
curl -s "https://www.awwwards.com/websites/<slug>/" | grep -o -m1 '<title>[^<]*</title>'
```

## Step 3. First-pass lookup

Fetch the URLs from step 2. Take three things: names currently listed, tags that repeat
across them, technologies in use.

**Label everything you get back as a lead, never as a fact.** The fetch tool summarizes
pages through a small model, so tag strings are not guaranteed verbatim and results are
cached for 15 minutes. Write "Awwwards currently surfaces a lot of X" and never "the tag
is exactly X". The user confirms by opening the link.

**If a fetch fails, do not stop.** Go to step 4 without it and record the gap in the
brief's "what we could not check" section. The lookup adds material; it is not a
precondition.

## Step 4. Three directions

The only place a human is in the loop. Each direction carries five things:

1. **A name, not an adjective.** "Calm clinical data", "High-contrast editorial". A name
   is arguable; "modern and clean" is not.
2. **Two or three real reference URLs.** Openable. From step 2 or 3.
3. **A palette.** The seven roles, a Coolors URL, and computed contrast ratios.
4. **A type pairing.** Display and body. Two families maximum.
5. **What would make this wrong.** The fact that, if true, kills this direction.

Three quality rules govern this step. All three are in
`references/direction-and-palette.md`; the short version:

- **Force distance.** The three must differ on at least two of: color temperature,
  density, type classification, ground (light-first or dark-first). State which axes they
  split on. Three variations of one idea make the choice meaningless.
- **Compute contrast, never estimate it.** Body text 4.5:1, large text and UI 3:1, in both
  light and dark. This is the one thing here a machine can settle, and it is where
  AI-generated palettes most often fail.
- **Verify the palette by searching backward.** Awwwards filters by color:
  `/websites/?tag=<aesthetic>&palette=%23<HEX>`. Read the *mood* of what comes back, not
  the count. Three different accents each returned a full page on 2026-09-02, so emptiness
  almost never fires. Off-mood results mean the palette does not belong to that aesthetic.

Present all three, let the user open links and pick.

**If they reject all three,** ask what was off and rebuild from step 2's vocabulary. Do not
regenerate directions against the same search terms; you will produce the same three.

**If the user refuses to choose and asks for one direction,** the gate has been handed to
you, not removed. Collapse to one and say that you did. Then split the five items by what
each is for. The three candidates, the distance rule, and a spread of reference links
exist to give the user a choice, so they can go. The palette roles, the computed
contrast, the type availability check, and "what would make this wrong" exist to make the
answer correct, so they stay.

"What would make this wrong" gets heavier, not lighter. With three directions on the
table it helps the user compare. With one, it is the only thing left that lets them
notice the choice does not fit their situation.


## Step 5. Freeze into a brief

Write the chosen direction to a file. Path, in this order: `docs/design/` if it exists,
else create it under an existing `docs/`, else the repo root. Filename is always
`design-brief.md`. Other agents have to find it, so the name is not negotiable.

**If the file already exists, do not overwrite it.** Read it, show the user, ask whether to
update.

Format is in `references/brief-template.md`. It includes a **rejected directions** section
with reasons. Without it the next session proposes the same rejected direction and the
user rejects it again for the same reason.

## Handoff

- Marketing or landing surface? Hand to `anti-slop-frontend`. It reads the brief and skips
  its own situation-read step.
- Product UI? Go straight to implementation with the brief as the source of tokens.

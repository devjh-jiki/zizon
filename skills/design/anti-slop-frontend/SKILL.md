---
name: anti-slop-frontend
description: >
  Stop AI-generated frontends from looking templated ("slop"). Read the brief
  first, infer the real design direction, then ship landing pages, portfolios,
  and redesigns that avoid the LLM defaults (AI-purple gradients, centered hero
  on dark mesh, three equal feature cards, Inter + slate-900, eyebrow label on
  every section, beige+brass premium-consumer palette). Three dials tune the
  output: DESIGN_VARIANCE, MOTION_INTENSITY, VISUAL_DENSITY. Use when building or
  reviewing a marketing/landing/portfolio UI and the goal is that it look
  intentional and premium — or when the user says "AI 티 안 나게", "슬롭 같지 않게",
  "템플릿 같지 않게", "감각적으로", "anti-slop", "make it not look AI", "good taste",
  "premium frontend". This is taste + AI-tell detection for marketing surfaces;
  for a systematic token-based design system across an app, use design-system
  instead. NOT for dashboards, data tables, or multi-step product UI.
---

# Anti-Slop Frontend

Most AI frontend output is bad because the model jumps to a default aesthetic instead of reading the brief. This skill is the discipline that stops that: read the room, pick a real direction, and actively avoid the tells that mark a page as machine-made.

**Scope:** landing pages, portfolios, marketing sites, redesigns. Not dashboards, not data tables, not multi-step product flows. Every rule here is *contextual* — read the brief, then pull only what fits. Nothing fires automatically.

> For a systematic, token-based design system spanning a whole app (base → semantic tokens, components, theming), use the `design-system` skill. This skill is about **taste and anti-slop detection on marketing surfaces**.

## 1. Read the room before anything else

Before touching code or dials, infer what the user actually wants. Signals to read:

1. **Page kind** — landing (SaaS / consumer / agency / event), portfolio (dev / designer / studio), redesign (preserve vs overhaul), editorial/blog.
2. **Vibe words** they used — "minimalist", "Linear-style", "Awwwards", "brutalist", "premium consumer", "Apple-y", "editorial", "playful", "serious B2B".
3. **Reference signals** — URLs, screenshots, products or brands they named.
4. **Audience** — B2B procurement panel vs. design-conscious consumer vs. recruiter scanning a portfolio. The audience picks the aesthetic, not your taste.
5. **Existing brand assets** — logo, color, type, photography. For redesigns these are starting material, not optional.
6. **Quiet constraints** — accessibility-first, public-sector, regulated, trust-first commerce, kids' products. These OVERRIDE aesthetic preference.

**Output a one-line "Design Read" before generating any code:**

> "Reading this as: `<page kind>` for `<audience>`, with a `<vibe>` language, leaning toward `<design system or aesthetic family>`."

If the brief is genuinely ambiguous, ask **exactly one** clarifying question (e.g. "closer to Linear-clean or Awwwards-experimental?"). If you can confidently infer, don't ask — declare the read and proceed.

## 2. The three dials

After the read, set three dials (1–10). Every layout/motion/density decision is gated by them. Baseline **8 / 6 / 4**; the read overrides it (see `references/dials-and-systems.md` for the inference table and presets).

- **DESIGN_VARIANCE** — 1 = perfect symmetry, 10 = artsy chaos
- **MOTION_INTENSITY** — 1 = static, 10 = cinematic / physics
- **VISUAL_DENSITY** — 1 = art gallery / airy, 10 = cockpit / packed data

## 3. Real system vs. aesthetic

Don't invent CSS for something that has an official package, and don't pretend a trend is an official system.

- **Brief reads as a named system** (Fluent, Material, Carbon, Polaris, Atlassian, Primer, GOV.UK, USWDS, Radix Themes, shadcn/ui, Tailwind)? Install and use the **official** package. Don't hand-recreate its CSS. One system per project. See `references/dials-and-systems.md`.
- **Brief is an aesthetic, not a system** (glassmorphism, bento, brutalism, editorial, dark-tech, aurora/mesh, kinetic type)? Build with native CSS + Tailwind + a maintained library, and be honest in comments about what's borrowed inspiration vs. official material. "Apple Liquid Glass" has **no** official web package — label web versions as approximations.

## 4. Anti-default discipline (the core of the skill)

Do not reach for the LLM defaults. These are the most-tested AI tells; avoid unless the brief explicitly asks:

- **AI-purple / blue glow** gradients and neon button halos. Use neutral bases (zinc/slate/stone) + one high-contrast accent, saturation < 80%.
- **Inter + slate-900** as the automatic default. Prefer Geist / Outfit / Satoshi / Cabinet Grotesk or a brand-appropriate face. (Inter is fine when the user asks for neutral/Linear-style or it's accessibility-first.)
- **Serif because "creative"** — banned as a default reflex. `Fraunces` and `Instrument Serif` specifically banned as defaults. Serif only when the brand names one or the family is genuinely editorial/luxury/heritage.
- **Centered hero on dark mesh** when DESIGN_VARIANCE > 4. Force split-screen, left-content/right-asset, or asymmetric whitespace.
- **Eyebrow label above every section** (`text-[11px] uppercase tracking-[0.18em]`). Max 1 per 3 sections. The #1 violated rule in production.
- **Beige/cream + brass/clay + espresso** for every premium-consumer brief. Banned as the default reach — rotate a different palette family each time.
- **Three equal feature cards**, div-based fake screenshots, generic glassmorphism on everything, infinite micro-animations on every card.

The full tell list, the banned premium-consumer hex families, and the palette-rotation rule live in `references/ai-tells.md`.

## 5. Non-negotiables (never simplify these away)

- **Accessibility:** WCAG AA contrast on every button, form field, placeholder, and focus ring. Audit CTAs (white-on-white, transparent-over-photo → banned) before shipping.
- **Reduced motion:** any motion above MOTION_INTENSITY 3 must honor `prefers-reduced-motion` and collapse to static.
- **Dark mode:** design both modes from the start; one theme locked per page (no light section mid-scroll in a dark page). No pure `#000`/`#fff`.
- **Real images:** even minimalist sites need real images. A pure-text page with gradient blobs is not minimalism, it's incomplete. Use an image-gen tool if available, real photo sources otherwise, or leave clearly-labeled placeholder slots and tell the user — never div-based fake screenshots.
- **Interactive states:** loading (skeletons matching final shape, not spinners), empty, error, and tactile `:active` feedback. Not just the happy state.
- **Motion must be motivated:** each animation communicates hierarchy, storytelling, feedback, or state change. "It looked cool" is not a reason.

## 6. Pre-flight check (before declaring done)

Mechanical pass — see `references/preflight.md` for the full checklist. The high-value ones:

- Hero fits the initial viewport; headline ≤ 2 lines, subtext ≤ 20 words, CTA visible without scroll.
- Nav renders on one line at desktop; height ≤ 80px.
- Eyebrow count ≤ ceil(sectionCount / 3).
- No two sections share the same layout family; ≤ 2 consecutive image+text zigzag rows.
- One accent color, one corner-radius scale, one copy register across the whole page.
- Copy self-audit: re-read every visible string; rewrite anything grammatically broken, AI-hallucinated cute wordplay, or fake-precise invented numbers.
- Button contrast, form contrast, CTA text fits one line, no duplicate-intent CTAs.

## Workflow

1. **Read** → state the one-line Design Read.
2. **Dials** → set VARIANCE / MOTION / DENSITY from the read.
3. **Foundation** → official system or honest aesthetic build (Section 3).
4. **Build** → apply anti-default discipline (Section 4) and the non-negotiables (Section 5).
5. **Pre-flight** → run the mechanical check (Section 6) before declaring done. On a redesign, audit the existing UI first (`references/preflight.md`).

## Attribution

Adapted from [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) (MIT) — the brief-inference "design read", the three dials, the official-system-vs-aesthetic split, the AI-tell catalogue, and the mechanical pre-flight check. Condensed into this SKILL.md with detail moved to `references/`; renamed and generalized for this repo. See THIRD_PARTY_NOTICES.md.

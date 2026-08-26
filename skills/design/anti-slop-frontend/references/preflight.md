# Pre-Flight Check & Redesign Protocol

Reference for the `anti-slop-frontend` skill. Run the mechanical pass before declaring any page done. On a redesign, run the audit first.

## Pre-flight check (mechanical, before "done")

**Hero**
- Fits the initial viewport. Headline ≤ 2 lines at desktop. Subtext ≤ 20 words AND ≤ 4 lines. CTAs visible without scroll.
- Font-scale planned with asset size. Default `text-4xl md:text-5xl lg:text-6xl`; `text-6xl md:text-7xl` only for 3–5 word headlines. A 4-line hero headline is a font-size error, never a copy-length error.
- Top padding ≤ `pt-24` at desktop. More reads as a layout bug.
- Max 4 text elements: (eyebrow OR brand strip OR neither) + headline + subtext + CTAs (1 primary + ≤ 1 secondary). Banned in hero: tagline below CTAs, trust micro-strip, pricing teaser, feature bullets, avatar row — all move to sections below.
- "Used by / Trusted by" logo wall goes UNDER the hero, never inside it.
- Hero needs a real visual. Text + gradient blob is a placeholder, not a hero.

**Navigation**
- Renders on a single line at desktop (`lg` 1024px). If it doesn't fit: condense labels, drop secondary items, or go hamburger. Two-line nav = broken.
- Height ≤ 80px desktop, default 64–72px.

**Rhythm & consistency**
- Eyebrow count ≤ ceil(sectionCount / 3). Count `uppercase tracking` small-caps labels.
- ≤ 2 consecutive image+text zigzag rows.
- Each layout family used at most once; ≥ 4 families on an 8-section page.
- One accent color across the whole page (no blue CTA in section 7 of a warm-grey site).
- One corner-radius scale (all-sharp, all-soft 12–16px, or all-pill) — mixed only with a documented, followed rule.
- One theme locked per page (no light-mode-warm-paper section in a dark page). Exception: one deliberate "theme switch on scroll" device, once per page.
- One copy register per page.

**Accessibility (a11y)**
- Button contrast WCAG AA (4.5:1 body, 3:1 large ≥ 18px). Banned: white button + white text, transparent button over the page with no border, ghost button over photo with no scrim/stroke.
- Form contrast: inputs, placeholders, focus rings, helper text, error text all pass AA.
- CTA text fits one line at desktop (≤ 3 words for primary, ideally 1–2). Wrapped CTA = fail.
- No duplicate-intent CTAs ("Get in touch" + "Contact us" + "Let's talk" = one intent → one label everywhere).
- Label above input, error text below, no placeholder-as-label ever.

**Motion & performance**
- Any motion above MOTION_INTENSITY 3 honors `prefers-reduced-motion` and collapses to static.
- Animate only `transform` and `opacity`; never `top`/`left`/`width`/`height`. `will-change` sparingly.
- LCP < 2.5s (hero image `priority`/preloaded), INP < 200ms, CLS < 0.1 (reserve space for images/fonts/embeds).
- Grain/noise on fixed `pointer-events-none` pseudo-elements only, never on scrolling containers.
- Z-index only for systemic layers (nav, modal, overlay, grain); document the scale.

**Copy self-audit**
- Re-read every visible string (headlines, subheads, eyebrows, button labels, body, captions, alt, footer, errors). Rewrite anything grammatically broken, with unclear referents, AI-hallucinated cute wordplay, or fake-precise invented numbers.

**Images**
- Even minimalist sites have ≥ 2–3 real images (hero + a product/lifestyle shot + one supporting). Use an image-gen tool if available; real photo sources otherwise; labeled placeholder slots + a note to the user as last resort. Never div-based fake screenshots. Logo walls use real SVG logos (Simple Icons / devicon), logos only (no category labels underneath).

## Redesign protocol

When the task is improving an existing UI (not greenfield):

1. **Audit first, don't restyle blindly.** Read the current UI and name its actual problems: layout, spacing, hierarchy, contrast, typography, motion, a11y. Produce the Design Read for where it should go (preserve vs overhaul).
2. **Preserve vs overhaul** comes from the brief. Preserve: keep the structure, fix spacing/hierarchy/contrast/type, dials ≈ existing +1 motion. Overhaul: dials +2 variance/motion, keep density.
3. **Respect existing brand assets** — logo, color, type, photography are starting material.
4. **Then apply** the anti-default discipline and non-negotiables from SKILL.md, and run this pre-flight before shipping.

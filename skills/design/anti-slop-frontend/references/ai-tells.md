# AI Tells (forbidden default patterns)

Reference for the `anti-slop-frontend` skill. Avoid these unless the brief explicitly asks for them. Each is a signature that marks a page as machine-generated.

## Visual & CSS
- No neon / outer glows by default. Use inner borders or subtle tinted shadows.
- No pure black (`#000000`) or pure white (`#ffffff`). Off-black (zinc-950) and off-white — pure values kill depth.
- No oversaturated accents. Max 1 accent, saturation < 80%.
- No excessive gradient text on large headers.
- No custom mouse cursors (outdated, a11y-hostile, perf-hostile).
- Tint shadows to the background hue; no pure-black drop shadows on light backgrounds.

## The Lila rule (AI purple)
The "AI purple / blue glow" aesthetic is the single most recognizable tell. No automatic purple button glows, no random neon gradients. Neutral base (zinc/slate/stone) + one high-contrast accent (emerald, electric blue, deep rose, burnt orange). If the brand explicitly asks for purple, embrace it — but execute with intent, not generic gradient slop. One accent, locked, used on the whole page.

## Typography
- Avoid Inter as the automatic default. Prefer Geist, Outfit, Satoshi, Cabinet Grotesk, or a brand face. Inter is acceptable for neutral/Linear-style or accessibility-first.
- No oversized H1s that just scream — control hierarchy with weight + color, not raw scale.
- **Serif discipline:** serif is very discouraged as a default. "Feels creative/premium" is NOT a reason. Banned as defaults: `Fraunces`, `Instrument Serif`. Serif only when the brand names one OR the family is genuinely editorial/luxury/publication/heritage AND you can articulate why this serif fits this brand. When justified, rotate (PP Editorial New, GT Sectra, Reckless Neue, Tiempos Headline, Recoleta, Cormorant, Playfair, EB Garamond, Canela, etc.) — don't reuse the same serif across consecutive projects.
- Emphasis within a headline: italic/bold of the SAME font. Never inject a random serif word into a sans headline.
- Italic display words with descenders (`y g j p q`): `leading-[1]` clips them. Use `leading-[1.1]` min + `pb-1` reserve.

## Premium-consumer palette ban (second-most-recurring tell)
For premium-consumer briefs (cookware, wellness, artisan, luxury, DTC home goods) the LLM default is warm beige/cream + brass/clay/oxblood/ochre + espresso text. Banned as default:
- Backgrounds: `#f5f1ea`, `#f7f5f1`, `#fbf8f1`, `#efeae0`, `#ece6db`, `#faf7f1`, `#e8dfcb`
- Accents: `#b08947`, `#b6553a`, `#9a2436`, `#9c6e2a`, `#bc7c3a`, `#7d5621`
- Text: `#1a1714`, `#1a1814`, `#1b1814`

Default alternatives (rotate, don't reuse): cold luxury (silver-grey + chrome + smoke), forest (deep green + bone + amber), black-and-tan, cobalt + cream, terracotta + slate, olive + brick + paper, pure monochrome + one saturated pop. Palette-rotation rule: if the last premium-consumer project used beige+brass, this one must use a different family. Override only when the brand explicitly names those colors.

## Layout
- Anti-center bias: centered hero avoided when DESIGN_VARIANCE > 4. Force split-screen, left-content/right-asset, asymmetric whitespace, or scroll-pinned structure. (Centered is OK for editorial/manifesto/launch briefs where the message is the design.)
- Cards only when elevation communicates real hierarchy — otherwise group with `border-t`, `divide-y`, negative space.
- Bento grids: exactly as many cells as you have content for (no empty middle/end tile); vary composition, don't stack 6 identical rows; at least 2–3 cells need real visual variation (image, brand gradient, pattern, tint), not white-on-white.
- Zigzag alternation cap: max 2 consecutive image+text-split rows; the 3rd is a pre-flight fail.
- Section-layout-repetition ban: each layout family appears at most once; an 8-section page uses ≥ 4 different families.
- Split-header ban: "left big headline + right small explainer paragraph" banned as default; stack vertically (headline on top, body below, max-width 65ch) unless the right column carries a real visual/interactive element.

## Eyebrow restraint (#1 violated rule)
An eyebrow is the small uppercase wide-tracking label above a section headline (`FOUR COLORWAYS`, `SELECTED WORK`). Every AI site puts one above every header → templated rhythm. Hard rule: **max 1 eyebrow per 3 sections** (hero counts as 1). If section A has one, the next 2 can't. Mechanical check: count `uppercase tracking` small-caps labels across sections; if count > ceil(sectionCount / 3), fail. Best fix: drop the eyebrow — the headline alone is enough.

## Content density
- Default per section: short headline (≤ 8 words) + short sub-paragraph (≤ 25 words) + one visual OR one CTA.
- No data-dump sections. A 20-row publication table / 30-row award list / giant pricing matrix on a marketing page is the wrong layout — use top 3–5 + "view full list", a marquee/carousel, or a separate page.
- Long lists (> 5 items) need a different component, not a longer list: 2-col split, card grid, tabs/accordion, scroll-snap pills, carousel, marquee. A 10-row spec sheet with a hairline under every row is the worst default (the "Marrow cookware" pattern) — group into 3 clusters or move to card-per-spec.
- Copy self-audit before ship: re-read every visible string. Rewrite anything grammatically broken, with unclear referents, sounding like AI hallucination (cute-but-wrong wordplay, forced metaphors), or fake-precise invented numbers (`92%`, `4.1×`, `5.8mm`) that don't come from real data.
- One copy register per page.

## Quotes & testimonials
- Max 3 lines of quote body. Cut longer quotes. Attribution = name + role + (optionally) company, never name-only. Real typographic quotes or none.

## Motion
- Motion must be motivated: hierarchy, storytelling, feedback, or state change — never "it looked cool".
- Marquee: max one per page.
- Motion claimed = motion shown: if MOTION_INTENSITY > 4, the page must actually move (entry transitions, scroll-reveal, hover physics). Can't ship working motion? Drop the dial to 3 and ship clean static. Never half-built motion (cut-off ScrollTriggers, jumpy enters, missing cleanups).
- Forbidden: `window.addEventListener('scroll', …)`, `window.scrollY` in React state, `requestAnimationFrame` loops touching React state.

# Dials & Design Systems

Reference for the `anti-slop-frontend` skill. Read after the Design Read is stated.

## Dial inference (design read → dial values)

| Signal | VARIANCE | MOTION | DENSITY |
|---|---|---|---|
| minimalist / clean / calm / editorial / Linear-style | 5–6 | 3–4 | 2–3 |
| premium consumer / Apple-y / luxury / brand | 7–8 | 5–7 | 3–4 |
| playful / wild / Dribbble / Awwwards / experimental / agency | 9–10 | 8–10 | 3–4 |
| landing page / portfolio / marketing site (default) | 7–9 | 6–8 | 3–5 |
| trust-first / public-sector / regulated / accessibility-critical | 3–4 | 2–3 | 4–5 |
| redesign — preserve | match existing | +1 | match existing |
| redesign — overhaul | +2 | +2 | match existing |

## Use-case presets

| Use case | VARIANCE | MOTION | DENSITY |
|---|---|---|---|
| Landing (SaaS, mainstream) | 7 | 6 | 4 |
| Landing (agency / creative) | 9 | 8 | 3 |
| Landing (premium consumer) | 7 | 6 | 3 |
| Portfolio (designer / studio) | 8 | 7 | 3 |
| Portfolio (developer) | 6 | 5 | 4 |
| Editorial / blog | 6 | 4 | 3 |
| Public-sector service | 3 | 2 | 5 |

## Dial definitions

**DESIGN_VARIANCE**
- 1–3: symmetrical grid, equal padding, centered alignment.
- 4–7: offset overlaps, varied aspect ratios, left-aligned headers over centered data.
- 8–10: masonry, fractional grid columns (`2fr 1fr 1fr`), large empty zones.
- Mobile: levels 4–10 collapse to strict single column below `md` (768px).

**MOTION_INTENSITY**
- 1–3: no auto animation; `:hover`/`:active` only.
- 4–7: `transition` on transform/opacity, `animation-delay` cascades for load-ins.
- 8–10: scroll-triggered reveals, parallax, scroll-driven animation. Never `window.addEventListener('scroll')` — use `useScroll`, ScrollTrigger, IntersectionObserver, or CSS `animation-timeline: view()`.

**VISUAL_DENSITY**
- 1–3: lots of whitespace, big section gaps (`py-32`+).
- 4–7: standard app spacing (`py-16`–`py-24`).
- 8–10: tight padding, no card boxes, 1px lines separate data, `font-mono` for numbers.

## Real design system → official package

If the brief reads as one of these, install the **official** package. Don't recreate its CSS by hand. One system per project.

| Brief reads as… | Package |
|---|---|
| Microsoft / enterprise SaaS / dashboards | `@fluentui/react-components` |
| Google-ish, Material-flavored | `@material/web` + Material 3 tokens |
| IBM-style B2B analytics | `@carbon/react` + `@carbon/styles` |
| Shopify app surfaces | Polaris |
| Atlassian / Jira-style | `@atlaskit/*` |
| GitHub-style devtool / community | `@primer/css` or `@primer/react-brand` |
| UK public-sector | `govuk-frontend` |
| US public-sector / trust-first | `uswds` |
| Modern accessible React foundation | `@radix-ui/themes` |
| Modern SaaS, you own the components | shadcn/ui (`npx shadcn@latest add …`) |
| Tailwind-based modern SaaS / AI marketing | Tailwind v4 utilities + `dark:` |

## Aesthetic (no official package) → honest build

For these, build with native CSS + Tailwind + a maintained library. Be honest in comments about borrowed inspiration vs. official material.

- Glassmorphism → `backdrop-filter` + layered borders + highlight overlay; solid-fill fallback under `prefers-reduced-transparency`.
- Bento → CSS Grid with mixed cell sizes. No library owns this.
- Brutalism / editorial / dark-tech / aurora-mesh / kinetic type → native CSS, no library.
- **Apple Liquid Glass** → no official `liquid-glass.css`. Web versions are `backdrop-filter` approximations; label as approximation.

## Default stack (when no named system is chosen)

- React / Next.js, Server Components by default; anything with motion/scroll/pointer is an isolated `'use client'` leaf.
- Tailwind v4 (use `@tailwindcss/postcss` or the Vite plugin, not the old `tailwindcss` postcss plugin).
- Motion (`motion/react`) for animation. Never `useState` for continuous values (mouse, scroll, pointer physics) — use `useMotionValue`/`useTransform`/`useScroll`.
- Fonts via `next/font` or self-hosted `@font-face` + `font-display: swap`. Never `<link>` to Google Fonts in production.
- Icons: one family per project (`@phosphor-icons/react`, `hugeicons-react`, `@radix-ui/react-icons`, `@tabler/icons-react`). Never hand-roll SVG icons.
- Verify every 3rd-party import against `package.json`; output the install command if missing.

# Reference sites

What each site gives you, the URL grammar, and the confirmed slugs. Verified by direct
fetch on 2026-09-02.

## What is readable and what is not

These sites carry their value in images. An agent reads pages as text. So this skill does
not scrape trends. It harvests **vocabulary and taxonomy**, which are text, and hands the
**visual judgment** to the user through filter URLs they open themselves.

| Site | Fetch | Readable as text | Not readable |
|---|---|---|---|
| Awwwards | 200, no login | Award-winner names, tags, technologies, categories | The actual designs |
| SaaSFrame | 200, no login | Category names and counts, section patterns, brands featured | The actual screens. Figma files are paid |
| Coolors | Trending renders colors in JS, no hex in the HTML | Nothing useful | Trending palettes |
| Mobbin | **403, bot-blocked** | Nothing | Everything |

**Mobbin is deliberately excluded.** It returns 403 to fetches, and driving a real browser
against a paid product was considered and declined. If you want it back, the options are a
logged-in Playwright session or asking the user to paste screenshots. Do not add it
without deciding that again.

**Coolors is for generating, not reading.** `coolors.co/<hex>-<hex>-<hex>-<hex>-<hex>`
returns 200 and opens the palette in the editor. Build the palette yourself, then export
the URL so the user can turn the dials by hand.

## Awwwards

One grammar for everything: `https://www.awwwards.com/websites/<slug>/`

Extras:

- Color filter: `https://www.awwwards.com/websites/?tag=<tag>&palette=%23<HEX>`
- Pagination: `/websites/<slug>/?page=2`
- Reset: `/websites/`

**Silent fallback, the trap on this site.** An unknown slug does not 404. It returns 200
and serves the unfiltered nominees list. `/websites/premium-saas-vibe/` and
`/websites/zzzz-not-a-real-tag/` both returned 200 with hundreds of kilobytes of real
content on 2026-09-02. Status codes cannot tell you the filter worked. **Check the page
title.** A live filter titles itself for the slug (`Best Minimal Websites | Web Design
Inspiration`); the fallback titles itself `Awwwards Nominees`. Assume the same fallback
applies to the `?tag=` half of the color query.

### Tags and styles

```
360 3d 404-pages about-page animation app-style big-background-images clean colorful
contact-page content-architecture copy-design data-visualization filters-and-effects
flat-design footer-design forms-and-input fullscreen gallery gestures-interaction
graphic-design header-design horizontal-layout icons illustration infinite-scroll
interaction-design menu-horizontal menu-vertical microinteractions minimal navigation
parallax photo-video photographic portfolio project-page responsive responsive-design
retro scrolling single-page social-integration sound-audio storytelling transitions
typography ui-design unusual-navigation vector video web-fonts
```

### Categories and industries

```
architecture art-illustration business-corporate culture-education design-agencies
e-commerce events experimental fashion film-tv food-drink games-entertainment
hotel-restaurant institutions luxury magazine-newspaper-blog mobile-apps music-sound
other photography promotional real-estate social-responsibility sports startups
technology web-interactive
```

### Technologies, the ones worth filtering on

```
react next-js vue-js nuxt-js svelte astro gatsby tailwind sass css3 typescript
three-js webgl gsap framer motion lottie locomotive-scroll swiper p5js pixijs
webflow shopify wordpress sanity prismic contentful figma vercel netlify
```

The full technology list runs past a hundred entries. If you need one that is not here,
open `/websites/` and read the real slug rather than guessing.

## SaaSFrame

Two grammars. `/browse` is a 404, so do not use it.

- Screen type: `https://www.saasframe.io/categories/<slug>`
- Section pattern: `https://www.saasframe.io/patterns/<slug>`

### Categories, screen types

```
landing-page pricing-page dashboard account-setup create-element about-page blog-feed
careers-page features-page case-studies 404-page customers-page demo-request
affiliate-page contact-page documentation press-page use-cases integrations-page
blog-template comparison-page download-page security-page academy webinars-page
enterprise-page events-page podcast-pages product-video ai-page changelog ebook-page
early-access-page thank-you-page faq impact-page newsletter-page developers-page
gdpr-compliance-page for-education-page integrations-library templates
```

The biggest collections as of 2026-09-02 are account-setup, user onboarding, landing-page,
pricing-page, and dashboard. That ranking is a lead, not a fact: it came from a summarized
fetch.

### Patterns, page sections

```
bento-grid testimonial footer call-to-action feature pricing stats faq
```

## Choosing which axis goes where

| Project signal | Site and path |
|---|---|
| Aesthetic, motion, layout, typography | Awwwards tags |
| Sector or industry feel | Awwwards categories |
| Tech already decided by the stack | Awwwards technologies |
| Which screen is being designed | SaaSFrame categories |
| Which section of a page | SaaSFrame patterns |
| Color | Awwwards palette query, plus a generated Coolors URL |

Two or three URLs per site. A wall of links is the same as no links.

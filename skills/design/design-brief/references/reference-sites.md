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
| Mobbin | 200, but redirects into a login-walled SPA shell | Nothing | Everything |

**Mobbin is deliberately excluded.** Fetching it is not blocked, it is pointless. A content
URL such as `/search/ios/flows?filter=kyc` answers 307 and lands on a login-walled SPA
shell holding two images, zero app links, and nothing but `Log in` and `Join for free`.
Driving a real browser against a paid product was considered and declined. If you want it
back, the options are a logged-in Playwright session or asking the user to paste
screenshots. Do not add it without deciding that again.

**This row used to say "403, bot-blocked", and that is no longer true.** Re-verified
2026-09-02. The decision to exclude it stands, but the reason is a login wall rather than
a bot block. Recording a status code was the mistake: 200 tells you as little here as it
does on Awwwards.

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
content on 2026-09-02. Status codes cannot tell you the filter worked. The page title is
the signal, and it comes in three shapes, not two:

| Title shape | Meaning | Example |
|---|---|---|
| Names the slug | The filter is live | `Best Minimal Websites`, `Best Examples of Typography in Web Design` |
| `Awwwards Nominees` | Silent fallback. The slug does not exist | `/websites/brutalism/` |
| Generic house title | Undecidable. Discard the URL | `graphic-design` returns `Winning websites. Web Design Inspiration - Awwwards` |

The third shape appears on slugs that do exist, so it is not proof of failure. It is
proof that you cannot tell, which for this purpose is the same thing. Pick a different
axis rather than guessing.

**The color filter works, but only in the query form.** `?tag=<slug>&palette=%23<HEX>`
filters. `/websites/<slug>/?palette=%23<HEX>` does not: the parameter is dropped and you
get the unfiltered tag straight back. Verified 2026-09-02, where the path form returned a
result set identical to the unfiltered tag while the query form replaced 12 of 31 entries.
**This is the silent-200 trap wearing a second costume,** and the title does not catch this
one either, because both forms keep the live filter title. Always build the URL in query
form.

**Never read the filter off a result count.** The first page renders 31 distinct sites
whether or not a palette is applied. Counting raw `/sites/` links gives 46 against 32, but
that gap is duplicate markup rather than filtering, so an earlier version of this file
cited it as evidence and was measuring nothing. The signal that does work is **how far the
result set moves**. Verified 2026-09-02: against `tag=minimal`, accent `#0E5A63` kept 19 of
31 and brought 12 new; against `tag=typography`, a deliberately foreign `#1B36F0` shared
only 2 and replaced 29. Compare the sets, never the counts.

**One transient to guard against.** A verification run once saw a filter page come back
200 with zero result cards, at roughly half the usual page size, and a retry returned a
full page. That was not reproducible in five attempts. Still, a zero-card page is
indistinguishable from a genuinely rare pairing, so **retry once before concluding
anything from an empty result.**

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

Harvested on 2026-09-02 from a category page's sidebar, **not from the homepage. The
homepage shows only part of the taxonomy.** An earlier version of this file listed 41
categories and 8 patterns taken from the homepage, and a verification run walked straight
into the gap: `user-onboarding`, `sign-up-flow`, `verification`, `steps`,
`progress-indicator` and `social-login` all return 200 and none of them were listed. Since
the confirmed list is the guard rather than a check performed afterwards, an incomplete
list fails in the wrong direction. Re-harvest like this:

```sh
curl -s -A "<browser UA>" https://www.saasframe.io/categories/account-setup \
  | grep -o 'href="/categories/[a-z0-9-]*"' | sed 's|.*/categories/||;s|"||' | sort -u
```

**Three slugs look like CMS artifacts and are not.** `upgrading-29385`, `maps-c7253` and
`comparison-d` carry random suffixes, and an earlier version of this file dropped them on
sight. Checking the titles killed that: `/categories/upgrading` is the Billing collection
and `/categories/upgrading-29385` is the actual Upgrading one; `/patterns/comparison` is
the Table collection and `/patterns/comparison-d` is the actual Comparison one. For those
two the clean name points somewhere else entirely. `maps` and `maps-c7253` are a third
shape: both are Maps collections, 18 entries against 16, so neither name is wrong and the
suffixed one is simply a second collection. **Do not prune this list by eye.** SaaSFrame returns 404 on a
slug that does not exist, so resolving is the test, and a title read settles what a slug
actually holds.

### Categories, screen types (77)

```
404-page about-page academy account-setup affiliate-page ai-page analytics
appearance-customization blog-feed blog-template calendar careers-page case-
studies changelog chat checklist checkout comparison-page confirmation
contact-page create-element customers-page dashboard delete-account demo-
request details developers-page documentation download-page early-access-page
ebook-page empty-state enterprise-page events-page faq features-page flowchart
for-education-page gdpr-compliance-page impact-page import-export inbox
integrations integrations-library integrations-page invite-team-members
landing-page loading-screen login newsletter-page plans playground podcast-
pages press-page pricing-page product-tour product-video referral-flow search
security-page settings share sign-up-flow success table team-members templates
text-editor thank-you-page upgrading upgrading-29385 usage use-cases user-
onboarding verification webinars-page welcome-screen
```

### Patterns, page sections (73)

```
add api api-key awards bento-grid blog-cards calculator calendar call-to-
action call-to-download checkbox clients-logo code-snippet color-picker
comparison comparison-d connect-third-party contact-form copy-to-clipboard
date-picker delete dropdown-menu empty-state faq feature file-uploader
flowchart footer graph import-export infinite-marquee integrations invite-
friends loading-placeholder loading-screen maps maps-c7253 metrics modal
multi-factor-authentication newsletter-form notification-banner opt-in
pagination persona pricing pricing-comparison progress-indicator radio-buttons
related-items remove reviews-rating segmented-control settings-preferences
shortcut side-panel signup slider social-login stats steps success-state tabs
tag tasks-to-do team testimonial text-field tile timeline toggle upgrade-
prompt usage-indicator
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

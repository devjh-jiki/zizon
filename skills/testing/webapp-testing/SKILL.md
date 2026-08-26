---
name: webapp-testing
description: Drive and test a local web app with Playwright — verify frontend behavior, click through flows, capture screenshots, read console/network logs. Use when the user wants to test a running web app, debug UI behavior, automate a browser flow, says "이 웹앱 테스트", "브라우저로 확인해줘", "playwright 로 클릭 테스트", or needs to verify what a page actually renders. For unit-testing pure logic use tdd; this is for real browser interaction.
---

# webapp-testing

Test a local web app by writing a small Playwright script and running it headless. The pattern is **reconnaissance-then-action**: render the page, inspect what's actually there, then act on real selectors — never guess selectors blind.

## Pick the runtime first (portability)

Playwright exists for both Node and Python. **Choose the one matching the project**, don't force Python:

- **Node/TS project (most opencode setups)** → use `@playwright/test`: `npm i -D @playwright/test` then `npx playwright install chromium`. This is the idiomatic, lighter path for JS-first repos and bundles browser management.
- **Python project** → use the `playwright` package: `pip install playwright` then `python -m playwright install chromium`.

Either way the first browser install downloads a few hundred MB of chromium — tell the user, and be aware CI sandboxes may block it. If a browser can't be installed, say so rather than faking a run.

## Flow

1. **Get the page up.** Static HTML can be opened directly via a `file://` URL. A dynamic app needs its dev server running first — start it (`npm run dev` etc.), wait until it's reachable, and remember to stop it when done. (Note: `file://` can't do `fetch`/ES-module imports/CORS — anything using those needs a real server, not a file URL.)
2. **Reconnaissance.** Navigate, then wait for the app to settle before inspecting. Prefer Playwright's web-first auto-waiting assertions (`expect(locator).to_contain_text(...)` / `toContainText`) over a blanket `networkidle` wait — auto-waiting is more reliable and is the current recommended default. Screenshot or read the DOM to discover what's rendered.
3. **Identify selectors** from the rendered state. Prefer descriptive, accessible selectors — `get_by_role`/`getByRole`, `text=`, labels, IDs — over brittle nth-child/XPath chains.
4. **Act and assert.** Click/type/navigate, then assert on the resulting state (text, URL, DOM, console, network). Wrap in `try/finally` (or use the test runner's fixtures) so the browser closes even when an assertion fails.

## Example (Node, static page)

```js
import { test, expect } from '@playwright/test';
test('clicking the button shows the result', async ({ page }) => {
  await page.goto('file:///abs/path/to/index.html');
  await page.getByRole('button', { name: 'Click me' }).click();
  await expect(page.locator('#result')).toContainText('Clicked!');
});
```
Run: `npx playwright test`. (Python equivalent: `sync_playwright()` + `expect(...).to_contain_text(...)`, launch chromium headless, close in `finally`.)

## Owner / leadership lens

For a developer who is also CEO/CTO/CFO/PM, a browser test is the only thing that proves the *user's* experience actually works:

- **It tests the contract the customer sees.** Unit tests prove functions; a Playwright flow proves "a person can log in and check out." That's the layer where lost revenue actually hides.
- **Spend it on the money paths.** Full browser tests are heavier than unit tests — put them on signup, checkout, and the few flows whose breakage costs trust or sales, not on every cosmetic detail.
- **A screenshot is a cheap audit trail.** Capturing before/after images turns "it works on my machine" into evidence you can show a teammate or attach to a bug — for the price of one line.

## Attribution

Adapted from [anthropics/skills `webapp-testing`](https://github.com/anthropics/skills/tree/main/skills/webapp-testing) (Apache-2.0), trimmed to the core reconnaissance-then-action workflow with a runtime-portability note. See THIRD_PARTY_NOTICES.md.

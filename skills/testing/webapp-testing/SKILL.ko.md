---
name: webapp-testing
description: Drive and test a local web app with Playwright — verify frontend behavior, click through flows, capture screenshots, read console/network logs. Use when the user wants to test a running web app, debug UI behavior, automate a browser flow, says "이 웹앱 테스트", "브라우저로 확인해줘", "playwright 로 클릭 테스트", or needs to verify what a page actually renders. For unit-testing pure logic use tdd; this is for real browser interaction.
---

# webapp-testing

작은 Playwright 스크립트를 써서 로컬 웹앱을 헤드리스로 테스트한다. 패턴은 **정찰 후 행동(reconnaissance-then-action)**: 페이지를 렌더하고, 실제로 뭐가 있는지 살핀 뒤, 진짜 셀렉터로 행동한다 — 셀렉터를 눈감고 추측하지 않는다.

## 먼저 런타임을 고른다 (포터빌리티)

Playwright 는 Node 와 Python 둘 다 있다. **프로젝트에 맞는 것을 고른다**, Python 을 강요하지 말고:

- **Node/TS 프로젝트(대부분의 opencode 셋업)** → `@playwright/test` 사용: `npm i -D @playwright/test` 후 `npx playwright install chromium`. JS-first 레포에 자연스럽고 가벼운 경로이며 브라우저 관리를 번들한다.
- **Python 프로젝트** → `playwright` 패키지 사용: `pip install playwright` 후 `python -m playwright install chromium`.

어느 쪽이든 첫 브라우저 설치는 수백 MB chromium 을 받는다 — 사용자에게 알리고, CI 샌드박스가 막을 수 있음을 유의한다. 브라우저를 설치할 수 없으면, 실행을 가짜로 꾸미지 말고 그렇게 말한다.

## 흐름

1. **페이지를 띄운다.** 정적 HTML 은 `file://` URL 로 바로 열 수 있다. 동적 앱은 dev 서버가 먼저 떠야 한다 — 띄우고(`npm run dev` 등), 닿을 때까지 기다리고, 끝나면 멈춘다. (참고: `file://` 는 `fetch`/ES 모듈 import/CORS 가 안 된다 — 이걸 쓰는 건 file URL 이 아니라 실제 서버가 필요하다.)
2. **정찰.** 내비게이트하고, 살피기 전에 앱이 안정될 때까지 기다린다. 통째 `networkidle` 대기보다 Playwright 의 web-first 자동 대기 단언(`expect(locator).to_contain_text(...)` / `toContainText`)을 선호한다 — 자동 대기가 더 안정적이며 현재 권장 기본값이다. 스크린샷이나 DOM 읽기로 렌더된 것을 발견한다.
3. **셀렉터 식별** — 렌더된 상태에서. 깨지기 쉬운 nth-child/XPath 체인보다 서술적·접근성 셀렉터(`get_by_role`/`getByRole`, `text=`, 라벨, ID)를 선호한다.
4. **행동하고 단언한다.** 클릭/입력/내비게이트한 뒤 결과 상태(텍스트, URL, DOM, 콘솔, 네트워크)를 단언한다. `try/finally`(또는 테스트 러너의 fixture)로 감싸 단언 실패 시에도 브라우저가 닫히게 한다.

## 예시 (Node, 정적 페이지)

```js
import { test, expect } from '@playwright/test';
test('clicking the button shows the result', async ({ page }) => {
  await page.goto('file:///abs/path/to/index.html');
  await page.getByRole('button', { name: 'Click me' }).click();
  await expect(page.locator('#result')).toContainText('Clicked!');
});
```
실행: `npx playwright test`. (Python 등가: `sync_playwright()` + `expect(...).to_contain_text(...)`, chromium 헤드리스 launch, `finally` 에서 close.)

## 오너 / 리더십 렌즈

CEO/CTO/CFO/PM 를 겸하는 개발자에게, 브라우저 테스트는 *사용자의* 경험이 실제로 동작함을 증명하는 유일한 것이다:

- **고객이 보는 계약을 테스트한다.** 유닛 테스트는 함수를 증명하고, Playwright 흐름은 "사람이 로그인하고 결제할 수 있다"를 증명한다. 잃은 매출이 실제로 숨는 층이 거기다.
- **돈 경로에 쓴다.** 풀 브라우저 테스트는 유닛 테스트보다 무겁다 — 모든 사소한 디테일이 아니라 가입·결제, 그리고 깨지면 신뢰나 매출을 잃는 몇 개 흐름에 둔다.
- **스크린샷은 싼 감사 추적이다.** 전/후 이미지를 잡으면 "내 컴퓨터에선 됨"이 동료에게 보여주거나 버그에 첨부할 수 있는 증거가 된다 — 한 줄 값으로.

## 출처

[anthropics/skills `webapp-testing`](https://github.com/anthropics/skills/tree/main/skills/webapp-testing) (Apache-2.0) 에서 가져와, 핵심 정찰-후-행동 워크플로우로 다듬고 런타임 포터빌리티 노트를 더했다. THIRD_PARTY_NOTICES.md 참고.

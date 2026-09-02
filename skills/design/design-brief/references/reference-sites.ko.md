# 레퍼런스 사이트

각 사이트가 무엇을 주는지, URL 문법, 확인된 슬러그. 2026-09-02 에 직접 조회해 확인했다.

## 무엇이 읽히고 무엇이 안 읽히는가

이 사이트들은 가치를 이미지로 나른다. 에이전트는 페이지를 글자로 읽는다. 그래서 이
스킬은 트렌드를 긁어오지 않는다. 글자인 **어휘와 분류**만 가져오고, **눈으로 하는
판단**은 사용자가 직접 여는 필터 URL 로 넘긴다.

| 사이트 | 조회 | 글자로 읽히는 것 | 안 읽히는 것 |
|---|---|---|---|
| Awwwards | 200, 로그인 불필요 | 수상작 이름, 태그, 기술, 카테고리 | 실제 디자인 |
| SaaSFrame | 200, 로그인 불필요 | 카테고리 이름과 개수, 섹션 패턴, 수록 브랜드 | 실제 화면. Figma 파일은 유료 |
| Coolors | 트렌딩이 색을 JS 로 그려서 HTML 에 hex 가 없다 | 쓸 만한 것 없음 | 트렌딩 팔레트 |
| Mobbin | **403, 봇 차단** | 없음 | 전부 |

**Mobbin 은 의도적으로 뺐다.** 조회에 403 을 돌려주고, 유료 서비스에 실제 브라우저를
붙이는 방법은 검토한 뒤 택하지 않았다. 다시 넣고 싶다면 선택지는 둘이다. 로그인된
Playwright 세션이거나, 사용자에게 스크린샷을 받는 것이다. 그 판단을 다시 하지 않은 채
넣지 않는다.

**Coolors 는 읽는 곳이 아니라 만드는 곳이다.**
`coolors.co/<hex>-<hex>-<hex>-<hex>-<hex>` 가 200 으로 열리며 편집기에 팔레트가 뜬다.
팔레트는 직접 만들고, URL 로 내보내 사용자가 손으로 돌려볼 수 있게 한다.

## Awwwards

전부 한 문법이다. `https://www.awwwards.com/websites/<슬러그>/`

추가로 있는 것.

- 색 필터: `https://www.awwwards.com/websites/?tag=<태그>&palette=%23<HEX>`
- 페이지: `/websites/<슬러그>/?page=2`
- 초기화: `/websites/`

**조용한 폴백, 이 사이트의 함정.** 없는 슬러그는 404 가 되지 않는다. 200 과 함께 필터가
걸리지 않은 전체 목록을 돌려준다. 2026-09-02 에 `/websites/premium-saas-vibe/` 와
`/websites/zzzz-not-a-real-tag/` 가 둘 다 200 으로 수백 킬로바이트의 진짜 내용을
돌려줬다. 상태 코드로는 필터가 걸렸는지 알 수 없다. **페이지 제목을 본다.** 필터가 살아
있으면 슬러그에 맞춰 제목이 붙고(`Best Minimal Websites | Web Design Inspiration`),
되돌아갔으면 `Awwwards Nominees` 다. 색 질의의 `?tag=` 쪽에도 같은 폴백이 있다고 본다.

### 태그와 스타일

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

### 카테고리와 업종

```
architecture art-illustration business-corporate culture-education design-agencies
e-commerce events experimental fashion film-tv food-drink games-entertainment
hotel-restaurant institutions luxury magazine-newspaper-blog mobile-apps music-sound
other photography promotional real-estate social-responsibility sports startups
technology web-interactive
```

### 기술, 걸러 볼 만한 것

```
react next-js vue-js nuxt-js svelte astro gatsby tailwind sass css3 typescript
three-js webgl gsap framer motion lottie locomotive-scroll swiper p5js pixijs
webflow shopify wordpress sanity prismic contentful figma vercel netlify
```

기술 목록 전체는 백 개가 넘는다. 여기 없는 것이 필요하면 `/websites/` 를 열어 실제
슬러그를 읽는다. 추측하지 않는다.

## SaaSFrame

문법이 둘이다. `/browse` 는 404 이므로 쓰지 않는다.

- 화면 종류: `https://www.saasframe.io/categories/<슬러그>`
- 섹션 패턴: `https://www.saasframe.io/patterns/<슬러그>`

### 카테고리, 화면 종류

```
landing-page pricing-page dashboard account-setup create-element about-page blog-feed
careers-page features-page case-studies 404-page customers-page demo-request
affiliate-page contact-page documentation press-page use-cases integrations-page
blog-template comparison-page download-page security-page academy webinars-page
enterprise-page events-page podcast-pages product-video ai-page changelog ebook-page
early-access-page thank-you-page faq impact-page newsletter-page developers-page
gdpr-compliance-page for-education-page integrations-library templates
```

2026-09-02 기준 수록량이 큰 쪽은 account-setup, 온보딩, landing-page, pricing-page,
dashboard 였다. 이 순위는 사실이 아니라 실마리다. 요약된 조회에서 나온 값이다.

### 패턴, 페이지 섹션

```
bento-grid testimonial footer call-to-action feature pricing stats faq
```

## 어느 축을 어디로 보내는가

| 프로젝트 신호 | 사이트와 경로 |
|---|---|
| 미감, 모션, 레이아웃, 타이포그래피 | Awwwards 태그 |
| 분야나 업종의 분위기 | Awwwards 카테고리 |
| 스택이 이미 정한 기술 | Awwwards 기술 |
| 무슨 화면을 만드는가 | SaaSFrame 카테고리 |
| 페이지의 어느 섹션인가 | SaaSFrame 패턴 |
| 색 | Awwwards 색 질의, 그리고 생성한 Coolors URL |

사이트당 URL 두세 개. 링크가 벽처럼 쌓이면 링크가 없는 것과 같다.

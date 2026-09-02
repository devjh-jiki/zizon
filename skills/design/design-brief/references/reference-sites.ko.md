# 레퍼런스 사이트

각 사이트가 무엇을 주는지, URL 문법, 확인된 슬러그. 2026-09-02 에 직접 조회해 확인했다.

## 무엇이 읽히고 무엇이 안 읽히는가

이 사이트들은 가치를 이미지로 나른다. 에이전트는 페이지를 글자로 읽는다. 그래서 이
스킬은 트렌드를 긁어오지 않는다. 글자인 **어휘와 분류**만 가져오고, **눈으로 하는
판단**은 사용자가 직접 여는 필터 URL 로 넘긴다.

| 사이트 | 조회 | 글자로 읽히는 것 | 안 읽히는 것 |
|---|---|---|---|
| Awwwards | 200, 로그인 불필요 | 수상작 이름, 태그, 기술, 카테고리 | 실제 디자인 |
| SaaSFrame | 200, 로그인 불필요 | 카테고리 이름과 개수, 섹션 패턴, 수록 브랜드, 데스크톱 화면 주소 | Figma 파일, 모바일 화면, 북마크. 셋 다 Pro |
| Coolors | 트렌딩이 색을 JS 로 그려서 HTML 에 hex 가 없다 | 쓸 만한 것 없음 | 트렌딩 팔레트 |
| Mobbin | 200 이지만 로그인 장벽 뒤의 SPA 껍데기로 넘어간다 | 없음 | 전부 |

**Mobbin 은 의도적으로 뺐다.** 차단당하는 것이 아니라 조회해도 얻을 것이 없다.
`/search/ios/flows?filter=kyc` 같은 내용 주소는 307 을 돌려주고, 따라가면 로그인 장벽
뒤의 SPA 껍데기가 나온다. 이미지 두 개와 `Log in`·`Join for free` 뿐이고 앱 링크는 하나도
없다. 유료 서비스에 실제 브라우저를 붙이는 방법은 검토한 뒤 택하지 않았다. 다시 넣고
싶다면 선택지는 둘이다. 로그인된 Playwright 세션이거나, 사용자에게 스크린샷을 받는
것이다. 그 판단을 다시 하지 않은 채 넣지 않는다.

**이 줄은 「403, 봇 차단」이라고 적혀 있었는데 그것은 더 이상 사실이 아니다.** 2026-09-02
에 다시 확인했다. 빼기로 한 결정은 그대로지만 이유는 봇 차단이 아니라 로그인 장벽이다.
애초에 상태 코드를 적어 둔 것이 잘못이었다. 여기서도 200 은 Awwwards 에서와 똑같이
아무것도 말해 주지 않는다.

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
돌려줬다. 상태 코드로는 필터가 걸렸는지 알 수 없다. 신호는 페이지 제목이고, 형태가
둘이 아니라 셋이다.

| 제목 형태 | 뜻 | 예 |
|---|---|---|
| 슬러그를 이름으로 부른다 | 필터가 살아 있다 | `Best Minimal Websites`, `Best Examples of Typography in Web Design` |
| `Awwwards Nominees` | 조용한 폴백. 그 슬러그는 없다 | `/websites/brutalism/` |
| 사이트 공통 제목 | 판정 불가. 그 URL 은 버린다 | `graphic-design` 이 `Winning websites. Web Design Inspiration - Awwwards` 를 낸다 |

셋째 형태는 실제로 존재하는 슬러그에서도 나오므로 실패의 증거가 아니다. 가릴 수 없다는
증거이고, 이 목적에서는 그것이 같은 뜻이다. 추측하지 말고 다른 축을 고른다.

**색 필터는 질의형에서만 작동한다.** `?tag=<태그>&palette=%23<HEX>` 는 거른다.
`/websites/<슬러그>/?palette=%23<HEX>` 는 거르지 않는다. 매개변수가 조용히 버려지고 필터
없는 태그 결과가 그대로 돌아온다. 2026-09-02 에 확인했다. 경로형은 필터를 걸지 않은
결과와 완전히 같았고, 질의형은 31건 중 12건을 갈아치웠다. **이것은 조용한 200 함정이 옷을
바꿔 입은 것이고,** 제목으로도 가릴 수 없다. 두 형태 모두 살아 있는 필터 제목을 그대로
유지하기 때문이다. 주소는 항상 질의형으로 만든다.

**필터가 걸렸는지를 결과 개수로 읽지 마라.** 첫 페이지는 팔레트를 걸든 안 걸든 서로 다른
사이트 31건을 그린다. `/sites/` 링크를 날것으로 세면 46 대 32 가 나오지만, 그 차이는
중복된 마크업이지 필터가 아니다. 이 파일의 앞 판본이 그 수치를 필터가 작동한 근거로
들었고, 실제로는 아무것도 재고 있지 않았다. 작동하는 신호는 **결과 집합이 얼마나
움직이는가**다. 2026-09-02 에 확인했다. `tag=minimal` 에 액센트 `#0E5A63` 을 걸면 31건 중
19건이 남고 12건이 새로 들어온다. `tag=typography` 에 일부러 이질적인 `#1B36F0` 을 걸면
겹치는 것이 2건뿐이고 29건이 갈린다. 개수가 아니라 집합을 비교한다.

**한 가지 일시적 현상에 대비한다.** 검증 실행에서 필터 페이지가 200 인데 결과 카드가
하나도 없고 크기가 평소의 절반쯤인 응답을 한 번 받은 일이 있었다. 재요청하니 정상으로
돌아왔다. 다섯 번 시도로는 재현되지 않았다. 그래도 카드가 0인 페이지는 정말로 드문
조합과 구분되지 않으므로, **결과가 비었을 때는 결론을 내기 전에 한 번 재요청한다.**

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

**Pro 로 잠기는 것은 셋뿐이고 화면은 거기 들지 않는다.** 2026-09-02 에 항목 단위로
세었다. Figma 파일, 모바일 버전 탭, 북마크 저장이 전부이고 셋 다 `data-ms-content="pro"`
로 표시된다. 데스크톱 화면은 목록 카드와 `og:image` 양쪽에 CDN 주소가 그대로 실려
있으며 로그인 없이 받아진다. 항목 페이지도 200 이고 제목, 브랜드 이름, 소속 분류,
명도 기조가 글자로 읽힌다.

**이 파일의 앞 판본은 「실제 화면」을 막히는 것으로 적어 두었다.** 그 줄을 읽은 검증
실행이 SaaSFrame 을 열어보지도 않고 「실제 화면은 유료 Figma 뒤에 있다」를 사용자에게
가는 브리프의 「검증하지 못한 것」에 그대로 옮겨 적었다. 확인하지 못한 것을 확인하지
못했다고 적는 것은 정직하지만, 문서가 틀린 것을 옮겨 적는 것은 그냥 틀린 것이다.
**이 파일이 「막힌다」고 적어 둔 것은 확인된 사실로 쓰이므로 실측 없이 적지 않는다.**

2026-09-02 에 카테고리 페이지의 사이드바에서 수확했다. **홈페이지에서 뽑지 않는다.
홈페이지는 분류 체계의 일부만 보여준다.** 이 파일의 앞 판본은 홈페이지에서 뽑은
카테고리 41개와 패턴 8개만 담고 있었고, 검증 실행이 정확히 그 빈칸을 밟았다.
`user-onboarding`, `sign-up-flow`, `verification`, `steps`, `progress-indicator`,
`social-login` 이 전부 200 인데 하나도 목록에 없었다. 확인된 목록은 사후 점검이 아니라
예방 장치이므로, 목록이 부족하면 틀리는 방향이 반대가 된다. 다시 수확하는 방법이다.

```sh
curl -s -A "<브라우저 UA>" https://www.saasframe.io/categories/account-setup \
  | grep -o 'href="/categories/[a-z0-9-]*"' | sed 's|.*/categories/||;s|"||' | sort -u
```

**CMS 잔여물처럼 보이는 슬러그 셋이 있는데 잔여물이 아니다.** `upgrading-29385`,
`maps-c7253`, `comparison-d` 는 무작위 접미사를 달고 있어서, 이 파일의 앞 판본이 보자마자
빼 버렸다. 제목을 확인하니 그 판단이 틀렸다. `/categories/upgrading` 은 Billing 모음이고
`/categories/upgrading-29385` 가 실제 Upgrading 이다. `/patterns/comparison` 은 Table
모음이고 `/patterns/comparison-d` 가 실제 Comparison 이다. 이 둘은 깔끔한 이름이 아예
다른 곳을 가리킨다. `maps` 와 `maps-c7253` 은 세 번째 형태다. 둘 다 Maps 모음이고 수록
개수만 18건과 16건으로 다르다. 어느 이름도 틀리지 않았고 접미사가 붙은 쪽이 그저 두
번째 모음일 뿐이다. **이 목록을 눈으로 쳐내지 않는다.** SaaSFrame 은 없는 슬러그에 404 를 주므로
열리는지가 검사이고, 무엇이 들었는지는 제목을 읽어야 정해진다.

### 카테고리, 화면 종류 (77개)

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

### 패턴, 페이지 섹션 (73개)

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

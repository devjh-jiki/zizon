# 다이얼 & 디자인 시스템

`anti-slop-frontend` 스킬용 레퍼런스. Design Read 진술 후에 읽는다.

## 다이얼 추론 (design read → 다이얼 값)

| 신호 | VARIANCE | MOTION | DENSITY |
|---|---|---|---|
| 미니멀 / 클린 / 차분 / 에디토리얼 / Linear 스타일 | 5–6 | 3–4 | 2–3 |
| 프리미엄 소비자 / 애플 같은 / 럭셔리 / 브랜드 | 7–8 | 5–7 | 3–4 |
| 플레이풀 / 와일드 / Dribbble / Awwwards / 실험적 / 에이전시 | 9–10 | 8–10 | 3–4 |
| 랜딩 페이지 / 포트폴리오 / 마케팅 사이트 (기본) | 7–9 | 6–8 | 3–5 |
| 신뢰 우선 / 공공 / 규제 / 접근성 크리티컬 | 3–4 | 2–3 | 4–5 |
| 리디자인 — 보존 | 기존 유지 | +1 | 기존 유지 |
| 리디자인 — 전면개편 | +2 | +2 | 기존 유지 |

## 유스케이스 프리셋

| 유스케이스 | VARIANCE | MOTION | DENSITY |
|---|---|---|---|
| 랜딩 (SaaS, 메인스트림) | 7 | 6 | 4 |
| 랜딩 (에이전시 / 크리에이티브) | 9 | 8 | 3 |
| 랜딩 (프리미엄 소비자) | 7 | 6 | 3 |
| 포트폴리오 (디자이너 / 스튜디오) | 8 | 7 | 3 |
| 포트폴리오 (개발자) | 6 | 5 | 4 |
| 에디토리얼 / 블로그 | 6 | 4 | 3 |
| 공공 서비스 | 3 | 2 | 5 |

## 다이얼 정의

**DESIGN_VARIANCE**
- 1–3: 대칭 그리드, 균등 패딩, 중앙 정렬.
- 4–7: 오프셋 오버랩, 다양한 종횡비, 중앙 데이터 위 좌측 정렬 헤더.
- 8–10: 매스너리, 분수 그리드 컬럼(`2fr 1fr 1fr`), 큰 빈 공간.
- 모바일: 레벨 4–10 은 `md`(768px) 아래에서 엄격한 단일 컬럼으로 붕괴.

**MOTION_INTENSITY**
- 1–3: 자동 애니메이션 없음; `:hover`/`:active` 만.
- 4–7: transform/opacity 에 `transition`, 로드인용 `animation-delay` 캐스케이드.
- 8–10: 스크롤 트리거 리빌, 패럴랙스, 스크롤 구동 애니메이션. `window.addEventListener('scroll')` 절대 금지 — `useScroll`, ScrollTrigger, IntersectionObserver, 또는 CSS `animation-timeline: view()` 사용.

**VISUAL_DENSITY**
- 1–3: 많은 여백, 큰 섹션 간격(`py-32`+).
- 4–7: 표준 앱 간격(`py-16`–`py-24`).
- 8–10: 타이트 패딩, 카드 박스 없음, 1px 선으로 데이터 구분, 숫자에 `font-mono`.

## 진짜 디자인 시스템 → 공식 패키지

브리프가 아래 중 하나로 읽히면 **공식** 패키지를 설치하라. CSS를 손으로 재현하지 마라. 프로젝트당 하나의 시스템.

| 브리프가 이렇게 읽힘… | 패키지 |
|---|---|
| Microsoft / 엔터프라이즈 SaaS / 대시보드 | `@fluentui/react-components` |
| Google 풍, Material 계열 | `@material/web` + Material 3 토큰 |
| IBM 스타일 B2B 분석 | `@carbon/react` + `@carbon/styles` |
| Shopify 앱 화면 | Polaris |
| Atlassian / Jira 스타일 | `@atlaskit/*` |
| GitHub 스타일 개발툴 / 커뮤니티 | `@primer/css` 또는 `@primer/react-brand` |
| 영국 공공 | `govuk-frontend` |
| 미국 공공 / 신뢰 우선 | `uswds` |
| 모던 접근성 React 기반 | `@radix-ui/themes` |
| 모던 SaaS, 컴포넌트를 소유 | shadcn/ui (`npx shadcn@latest add …`) |
| Tailwind 기반 모던 SaaS / AI 마케팅 | Tailwind v4 유틸리티 + `dark:` |

## 미감 (공식 패키지 없음) → 정직한 빌드

이것들은 네이티브 CSS + Tailwind + 유지보수되는 라이브러리로 만들어라. 주석에서 빌려온 영감 vs 공식 재료를 정직하게 밝혀라.

- 글래스모피즘 → `backdrop-filter` + 레이어드 보더 + 하이라이트 오버레이; `prefers-reduced-transparency` 하에서 솔리드-필 폴백.
- 벤토 → 혼합 셀 크기의 CSS Grid. 이걸 소유하는 라이브러리 없음.
- 브루탈리즘 / 에디토리얼 / 다크테크 / 오로라-메시 / 키네틱 타입 → 네이티브 CSS, 라이브러리 없음.
- **Apple Liquid Glass** → 공식 `liquid-glass.css` 없음. 웹 버전은 `backdrop-filter` 근사치; 근사치라고 라벨.

## 기본 스택 (이름 있는 시스템을 고르지 않을 때)

- React / Next.js, 기본 Server Components; 모션/스크롤/포인터가 있는 건 격리된 `'use client'` 리프.
- Tailwind v4 (옛 `tailwindcss` postcss 플러그인이 아니라 `@tailwindcss/postcss` 또는 Vite 플러그인 사용).
- 애니메이션은 Motion(`motion/react`). 연속 값(마우스, 스크롤, 포인터 피직스)에 절대 `useState` 금지 — `useMotionValue`/`useTransform`/`useScroll` 사용.
- 폰트는 `next/font` 또는 셀프호스트 `@font-face` + `font-display: swap`. 프로덕션에서 Google Fonts `<link>` 절대 금지.
- 아이콘: 프로젝트당 하나의 패밀리(`@phosphor-icons/react`, `hugeicons-react`, `@radix-ui/react-icons`, `@tabler/icons-react`). SVG 아이콘 손으로 그리기 금지.
- 모든 서드파티 import 를 `package.json` 에 대조; 없으면 설치 명령 출력.

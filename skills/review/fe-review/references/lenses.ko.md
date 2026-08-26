# 6개 렌즈

각 렌즈는 질문 하나, diff 에 대조할 체크리스트, before/after 예시 하나로 구성된다. 예시는 전부 이 스킬 작성자 본인 소유 저장소 셋 — `jjan/apps/web`, `kalyx`, `jihoon-blog` — 에서만 가져왔고, 어떤 동료의 사적인 자료도 쓰지 않았다. 실제 저장소가 렌즈의 *좋은* 쪽을 보여줄 때는 *before* 를 가상의 대조군으로 표시했다(실제 파일을 억지로 허수아비로 만들지 않았다). 실제 저장소가 냄새 나는 쪽을 보여줄 때는 *after* 를 제안하는 수정으로 표시했다(실제로 반영됐다는 주장이 아니다).

---

## 1. 요구사항 추적성 (Requirement traceability)

**질문:** 이 코드가 무슨 요구사항을 만족시키는지 읽히나?

**체크리스트:**
- 매직 값(허용 목록, 임계값, 특정 이름)이 왜 그 값인지 근처에 적혀 있나?
- 커밋/PR 설명에만 있고 코드에는 없는 결정이 있나? (6개월 뒤엔 그 설명을 아무도 못 찾는다.)
- "왜 안 했는가"가 "무엇을 했는가"보다 중요한 곳에서 후자만 적혀 있나?
- 요구사항이 바뀌면 이 코드의 어느 줄을 고쳐야 하는지 짐작이 되나?
- 같은 로직이 여러 곳에 흩어져 있어 요구사항이 한 곳에서 안 읽히나?

**예시 — `jihoon-blog/src/lib/crawler-policy.ts` (실제, 현재 코드)**

Before (현재 배포된 코드):

```ts
export function getCrawlerRules(): CrawlerRule[] {
  return [
    { userAgent: 'Googlebot', allow: '/' },
    { userAgent: ['OAI-SearchBot', 'ChatGPT-User', 'GPTBot'], allow: '/' },
    {
      userAgent: ['Claude-SearchBot', 'Claude-User', 'ClaudeBot'],
      allow: '/',
    },
    { userAgent: ['PerplexityBot', 'Perplexity-User'], allow: '/' },
    { userAgent: '*', allow: '/' },
  ]
}
```

*무엇을* 했는지는 분명하다 — 허용된 User-Agent 목록. *왜* 는 안 보인다. 맨 아래 `{ userAgent: '*', allow: '/' }` 가 이미 전체를 허용하고 있어서, 위의 AI 크롤러 세 항목은 기능상 중복이다. 나중에 이 코드를 보는 사람은 이 항목들이 실제 결정(AI 답변 엔진에 노출을 의도적으로 열어 둠)을 담고 있는지, 아무도 못 지운 죽은 코드인지 구분할 수 없다. "지워도 안전해 보인다"와 "지워도 안전하다"는 다른 주장인데, 코드는 이 둘을 구분할 근거를 주지 않는다.

After (제안 — 실제로 반영됐다는 주장 아님):

```ts
export function getCrawlerRules(): CrawlerRule[] {
  return [
    { userAgent: 'Googlebot', allow: '/' },
    // AI 검색·답변 엔진에 색인을 명시적으로 허용한다 (GEO 전략).
    // '*' 규칙이 이미 전체 허용이라 이 세 항목은 기능적으로 no-op 이지만,
    // "개별 봇을 의도적으로 열어 뒀다"는 결정 자체를 로봇 파일에 남겨 둔다.
    { userAgent: ['OAI-SearchBot', 'ChatGPT-User', 'GPTBot'], allow: '/' },
    {
      userAgent: ['Claude-SearchBot', 'Claude-User', 'ClaudeBot'],
      allow: '/',
    },
    { userAgent: ['PerplexityBot', 'Perplexity-User'], allow: '/' },
    { userAgent: '*', allow: '/' },
  ]
}
```

주석 한 줄이 "이거 중복이니 지운다"는 그럴듯한 정리 PR을, 누군가 의식적으로 되돌려야 하는 결정으로 바꾼다.

---

## 2. 추상화 비용 (Abstraction cost)

**질문:** 이 추상화가 벌어들이는 것보다 비싸지 않나?

**체크리스트:**
- 이 레이어를 지우면 호출부가 실제로 더 복잡해지나, 아니면 그냥 한 단계 줄어드나?
- 이 추상화가 막아주는 구체적 버그·사고가 있나, 아니면 "나중에 필요할 것 같아서"인가?
- 구현체가 하나뿐인데 인터페이스가 이미 여러 구현을 가정하고 있나 (YAGNI)?
- 이 레이어를 이해하려면 몇 개 파일을 오가야 하나 — 그 이동 비용이 매번 지불되나?
- 이 추상화를 쓰는 곳들이 실제로 서로 다른 동작이 필요한가, 아니면 우연히 같은 코드가 두 번 있을 뿐인가?

**예시 — `kalyx/packages/adapter-date-fns/src/index.ts` + `kalyx/packages/core/src/types.ts` (실제, 현재 코드)**

`@kalyx/core` 는 `DateAdapter` 인터페이스(`parse`, `format`, `addDays`, `isBefore`, `today`, …)를 정의하고, 세 개의 별도 패키지(`adapter-date-fns`, `adapter-luxon`, `adapter-dayjs`)가 이를 구현한다. 실제로 존재하는 간접화다 — 피커 컴포넌트의 모든 날짜 연산이 날짜 라이브러리를 직접 부르지 않고 이 인터페이스를 거친다.

Before (가상 — 어댑터 없이 하위 라이브러리를 직접 호출했다면):

```ts
// 예시 (가상) — DateAdapter 없이 date-fns 를 직접 호출했다면
import { addDays } from 'date-fns';

function nextCalendarDay(iso: string): string {
  return addDays(new Date(iso), 1).toISOString();
}
```

레이어 하나를 아낀 것처럼 보인다. 그런데 실제 버그도 함께 물려받는다: `date-fns` 의 `addDays` 는 *로컬* 날짜 필드를 변형한다. 달력 그리드가 날짜를 하루씩 순회하며 DST 전환 구간을 지나면, 이 드리프트가 DST 를 관측하는 시간대 사용자에게 UTC 하루를 중복시키거나 건너뛴다.

After (실제, `kalyx/packages/adapter-date-fns/src/index.ts`):

```ts
/**
 * Add days in UTC. A UTC day is exactly 86_400_000 ms (no DST), so this keeps a
 * UTC-midnight instant at UTC midnight n days later — unlike date-fns' `addDays`,
 * which mutates the LOCAL date field and drifts by an hour when the runtime's
 * timezone crosses a DST transition in the iterated range (the calendar grid
 * iterates day-by-day, so that drift duplicated/skipped a UTC day for users in a
 * DST zone — e.g. Asia/Seoul, which observed DST in 1987–88).
 */
function utcAddDays(d: Date, n: number): Date {
  return new Date(d.getTime() + n * 86_400_000);
}
```

이 추상화는 투기적인 일이 아니라 실제 일을 하고 있다: 이름이 붙은 실제 버그를 고쳤고, `kalyx/packages/adapter-date-fns/src/__tests__/conformance.test.ts` 가 공유 적합성 스위트(`runAdapterConformanceTests`)를 세 어댑터 구현 모두에 돌려 서로 일치함을 증명한다 — 이게 바로 다중 구현 인터페이스가 벌어들여야 하는 실제 대가다. `kalyx/packages/react/src/internal/defaultAdapter.ts` 도 이 경계를 우연이 아니라 의도로 만든다: `headless` 진입점은 기본 어댑터를 절대 설치하지 않고, 어댑터가 안 넘어오면 나중에 날짜 연산 안쪽에서 알 수 없는 오류로 실패하는 대신 그 자리에서 해결 힌트와 함께 던진다.

이것이 렌즈 2를 적용해서 "비용이 정당하다"는 결론에 이르는 모습이다 — 이 지적은 결함이 아니라, 이 레이어가 왜 남아야 하는지 기록된 근거다.

---

## 3. 상태의 위치 (State placement)

**질문:** 전역·컨텍스트로 올라간 상태가 정말 그 자리여야 하나?

**체크리스트:**
- 지금 이 상태를 읽는 소비처가 몇 개인가? 소비처가 하나면 전역 스토어일 이유가 없다.
- "나중에 재사용할 수도 있으니"가 유일한 근거인가?
- 이걸 승격시키면 리마운트·뒤로가기·새로고침에서 값이 어떻게 되는지 설계했나 — 아니면 URL 이 이미 더 나은 답을 갖고 있나?
- prop 2~3단을 피하려고 context/전역으로 도망친 건 아닌가 — 읽기엔 드릴링이 더 쌀 때가 있다.
- 전역 상태 하나에 생명주기가 서로 다른 값들(예: 세션 범위 입력값과 페이지 이동에 따른 위치)이 같이 묶여 있나?

**예시 — `jjan/apps/web/app/calculators/commute/commute-flow.tsx` + `draft.ts` (실제, 현재 코드)**

Before (가상 — "나중에 재사용"을 이유로 초안을 전역 스토어로 올렸다면):

```ts
// 예시 (가상) — 두 번째 소비처가 없는데 전역 스토어로 올렸다면
export const useCommuteDraftStore = create<{
  draft: CommuteDraft;
  setDraft: (draft: CommuteDraft) => void;
}>((set) => ({
  draft: createEmptyDraft(),
  setDraft: (draft) => set({ draft }),
}));
```

이걸 읽는 화면은 하나뿐이다. 승격시켜도 지금 당장 얻는 게 없고, 대신 상태가 원래 소유해야 할 컴포넌트보다 오래 살아남는 새로운 자리가 생긴다 — 아무도 설계하지 않은 방식으로 내비게이션을 넘나들면서.

After (실제, `jjan/apps/web/app/calculators/commute/commute-flow.tsx`):

```tsx
/**
 * 단계 위치는 URL(`?step=n`)에, 입력값은 이 컴포넌트의 상태에 둔다. 전역 스토어는
 * 두 번째 소비처가 생기기 전까지 두지 않는다 (CC-NFR-004).
 * ...
 */
function HydratedCommuteFlow() {
  ...
  /* 마운트할 때 딱 한 번 세션에서 되살린다 (CC-FR-002). 없거나 망가졌으면 빈 폼이다 */
  const [draft, setDraft] = useState<CommuteDraft>(
    () => readDraft(globalThis.sessionStorage) ?? createEmptyDraft(),
  );
```

서로 다른 종류의 상태 두 가지가 의도적으로 각자 다른, 전역이 *아닌* 자리를 갖는다: 단계 위치는 URL(`?step=n`)에 둬서 뒤로가기·앞으로가기·새로고침이 공짜로 동작하고, 폼 입력값은 컴포넌트 상태에 두되 새로고침 생존을 위해 세션 스토리지 미러(`draft-storage.ts`)를 둔다 — 스토어가 아니고, 서버로도 보내지 않는다고 명시했다. 주석이 승격 규칙 자체를 정책으로 못박아 둔다("두 번째 소비처가 생기기 전까지 전역 스토어를 두지 않는다") — 이게 바로 이 렌즈가 확인하려는 것이다.

---

## 4. 인터페이스 예측가능성 (Interface predictability)

**질문:** 이름과 시그니처가 실제 동작과 일치하나?

**체크리스트:**
- 함수 이름의 동사가 실제로 하는 일 전부를 포함하나 — 호출자가 이름만 보고 부작용을 짐작할 수 있나?
- 반환 타입이 실패·빈 값·부분 값 케이스를 감추고 있나?
- 같은 이름의 함수가 시그니처에 없는 숨은 내부 상태에 따라 다른 필드를 바꾸나?
- 인자 순서·타입이 근처 유사 함수의 관례를 깨나 (콜백이 어떤 함수는 앞, 어떤 함수는 뒤)?
- JSDoc 이 시그니처만으로는 알 수 없는 동작까지 설명해야 하나 — 그렇다면 그 자체가 "이름·시그니처가 부족하다"는 증거다.

**예시 — `kalyx/packages/react/src/hooks/useRangePicker.ts` (실제, 현재 코드)**

```ts
export interface UseRangePickerReturn {
  /** Handler for clicking a single date */
  selectDate: (iso: ISODateString) => void;
  ...
}
```

```ts
const selectDate = useCallback(
  (iso: ISODateString) => {
    const normalized = /* ... */;
    if (selectingTarget === 'start') {
      if (!setRange({ start: normalized, end: null })) return;
      setSelectingTarget('end');
      setHoverDate(null);
    } else {
      const start = currentValue.start;
      // ... adapter.isBefore 로 start/end 가 바뀔 수 있다
      if (!setRange(newRange)) return;
      setSelectingTarget('start');
      setHoverDate(null);
      setIsOpen(false); // 이 분기에서만
    }
  },
  [selectingTarget, currentValue.start, adapter, setRange, displayTimezone],
);
```

`selectDate: (iso: ISODateString) => void` 라는 시그니처는 호출할 때마다 같은 일을 한다고 약속한다. 실제로는 아니다: 어느 필드가 바뀌는지(`start` 인지 `end` 인지), 두 날짜가 뒤바뀌는지(`adapter.isBefore` 로 재정렬됨), 팝오버가 닫히는지가 전부 시그니처엔 없는 숨은 `selectingTarget` 필드에 달려 있다. `useRangePicker` 는 완전히 커스텀한 UI를 만들 때 쓰라고 문서화된 훅이라, 이 훅을 감싸 자기 팝오버 열고 닫기 로직을 짜는 호출자는 이름과 시그니처만 보고는 `selectDate(iso)` 호출이 언제 자기 팝오버를 닫아버릴지 예측할 방법이 없다.

After (제안 — 예시용. 공개 API 이름을 바꿀 필요는 없지만, 계약이 구현부 안에 숨어 있으면 안 된다):

```ts
export interface UseRangePickerReturn {
  /**
   * Selects the date for whichever endpoint is next — see `selectingTarget`.
   * Completing `end` (a) may swap the two dates if `iso` is before the
   * current `start`, and (b) closes the popover as a side effect. Starting
   * a new range (calling this when a range is already complete) does not
   * close it.
   */
  selectDate: (iso: ISODateString) => void;
  ...
}
```

구현을 하나도 안 바꿔도 되는 수정이다 — 소스를 열기 전에 독자가 보는 계약만 바뀐다.

---

## 5. 비동기 UX (Async UX)

**질문:** 로딩·에러·빈 상태가 설계되었나?

**체크리스트:**
- 로딩이 오래 걸리면(1초 이상) 사용자에게 다른 신호를 주나, 아니면 계속 같은 무언의 스피너인가?
- 오프라인/네트워크 실패와 서버 오류(4xx/5xx)를 같은 화면으로 뭉개나?
- 실패 후 재시도가 입력을 보존하나, 아니면 폼을 초기화하나?
- 느린 첫 요청이 빠른 두 번째 요청보다 늦게 도착했을 때 화면이 옛 결과로 덮이는 경쟁 상태를 막았나?
- "빈 결과", "아직 안 불러옴", "불러오다 실패"가 화면에서 눈에 띄게 구분되나, 아니면 다 똑같이 보이나?

**예시 — `jjan/apps/web/app/calculators/commute/use-calculation.ts` + `calculation-error.tsx` (실제, 현재 코드)**

Before (가상 — 이 렌즈가 잡아내려는 흔한 모양):

```ts
// 예시 (가상) — 로딩을 boolean 하나로 뭉개면
const [isLoading, setIsLoading] = useState(false);
const [error, setError] = useState<string | null>(null);

async function run() {
  setIsLoading(true);
  try {
    const res = await calculateCommuteCost(body);
    setResult(res.data);
  } catch {
    setError('오류가 발생했습니다');
  } finally {
    setIsLoading(false);
  }
}
```

"아직 빠른 편"과 "오래 걸리는 중"이 구분되지 않는다. 오프라인과 503 이 같은 일반 문구가 된다. 느린 첫 `run()` 이 두 번째 호출보다 늦게 끝나 결과를 덮어써도 막을 방법이 없다. 재시도는 그냥 폼에 지금 남아 있는 값으로 같은 함수를 다시 부를 뿐 — 그 사이에 입력이 지워지지 않았다는 보장이 없다.

After (실제, `jjan/apps/web/app/calculators/commute/use-calculation.ts`):

```ts
export type CalculationState =
  | { kind: 'idle' }
  /** `slow` 는 1초를 넘겨 진행 문구를 띄워야 하는 상태 */
  | { kind: 'loading'; slow: boolean }
  | { kind: 'success'; result: CalculateCommuteOutputBody }
  | { kind: 'failed'; plan: ProblemPlan }
  /** 요청이 서버에 닿지도 못했다. 오프라인이 대표적이다 */
  | { kind: 'offline' };
```

훅은 `requestId` 를 추적해서 아직 최신인 응답만 반영한다 — 느린 첫 요청이 빠른 두 번째 요청을 덮어쓸 수 없다. `SLOW_NOTICE_AFTER_MS`(1000ms) 타이머가 `loading.slow` 를 켜서, 오래 걸리면 무언의 스피너 대신 진행 문구가 뜬다. `calculation-error.tsx` 는 오프라인, "점검 중"(`retryAfterSeconds` 를 반영한 문구와 재시도 버튼 없음 — 점검 중에 재시도해 봐야 같은 실패만 반복하므로), 일반 실패를 서로 다른 화면으로 렌더링하며, 전부 여전히 채워진 폼 위에 얹혀 입력을 절대 지우지 않고, 그렇다고 사용자에게 명시적으로 알린다("입력한 내용은 그대로 남아 있어요"). 토스트를 안 쓰기로 한 결정도 주석으로 남아 있다("사라지면 무엇이 잘못됐는지 다시 볼 수 없다").

---

## 6. 숨은 동작 (Hidden side effects)

**질문:** 호출자가 모르는 부수효과가 있나?

**체크리스트:**
- 함수가 인자로 받지 않은 것(현재 시각, 랜덤값, 전역 설정)을 몰래 읽어서 결과를 바꾸나?
- 반환값의 이름이 "원본 그대로"를 암시하는데 실제로는 가공·보정된 값인가?
- 호출 한 번이 로깅·캐시 쓰기·외부 호출 같은 이름에서 짐작 못 할 부가 작업을 하나?
- 호출자가 이 동작을 알고 있다는 근거(주석, 타입, 테스트)가 있나?
- 같은 입력으로 두 번 불렀는데 다른 결과가 나오고, 그 이유가 시그니처에 없나?

**예시 — `jihoon-blog/src/lib/google-analytics.ts` + `daily-visitor-baseline.ts` (실제, 현재 코드)**

```ts
// src/lib/google-analytics.ts
export async function getAnalyticsStats(): Promise<AnalyticsStats> {
  const stats = await getCachedAnalyticsStats();

  return {
    totalPageViews: stats.totalPageViews,
    todayVisitors: addDailyVisitorBaseline(stats.todayVisitors),
  };
}
```

```ts
// src/lib/daily-visitor-baseline.ts
export function addDailyVisitorBaseline(
  activeUsers: number,
  date: Date = new Date(),
): number {
  return activeUsers + getDailyVisitorBaseline(date);
}
```

`AnalyticsStats.todayVisitors` 는 "GA 에서 온 오늘의 실제 방문자 수"처럼 읽힌다. 아니다: 호출할 때마다 날짜로 시드된 오프셋(10~40, 그날엔 고정값)이 몰래 더해진 뒤 반환된다. 타입은 그냥 `number` 다. 이 값을 렌더링하는 `AnalyticsStats.tsx` 어디에도 이게 보정된 값이라는 표시가 없다. 이 보정이 왜 있는지는 — 아마도 "오늘 1명" 같은 특정 숫자가 그 한 명의 방문자를 특정하지 못하게 막는 목적이겠지만 — 그 이유가 이 값을 적용하는 함수 근처 어디에도, 이 값을 쓰는 호출자 근처 어디에도 적혀 있지 않다.

After (제안 — 예시용. 앞으로 이 값을 볼 사람이 반드시 보게 되는 자리, 즉 타입 선언부에 보정 사실을 남긴다):

```ts
export interface AnalyticsStats {
  totalPageViews: number;
  /**
   * GA 실측치가 아니다. 특정 방문자 수(예: "오늘 1명")로 개별 방문자가 추정되지
   * 않도록 날짜 시드 오프셋(10~40)을 더한 값이다. 실측치가 필요하면
   * `getCachedAnalyticsStats()` 를 직접 호출한다.
   */
  todayVisitors: number;
}
```

고치는 대상은 동작 자체가 아니라 가시성이다 — 앞으로 이 코드를 보는 사람이 반드시 지나칠 자리에 그 사실을 옮겨 둔다.

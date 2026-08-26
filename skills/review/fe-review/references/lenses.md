# The Six Lenses

Each lens is a question, a checklist to walk against the diff, and one before/after example. Examples are drawn from three of this skill's author's own repositories — `jjan/apps/web`, `kalyx`, `jihoon-blog` — never from any private colleague material. Where the real repo shows the *good* side of a lens, the *before* is a labeled, hypothetical contrast (not a stretch of a real file into a strawman). Where the real repo shows the smell, the *after* is a labeled, suggested fix — not a claim that it shipped.

---

## 1. 요구사항 추적성 (Requirement traceability)

**Question:** Does this code read as satisfying some stated requirement?

**Checklist:**
- Do magic values (allow-lists, thresholds, specific names) explain nearby why they're that value?
- Is a decision that only exists in a commit message or PR description absent from the code itself? (In six months, nobody finds that description.)
- Where "why not" matters more than "what," is only the "what" written down?
- If the requirement changes, is it obvious which lines to touch?
- Is the same rule scattered across several places so no single place lets you read the requirement?

**Example — `jihoon-blog/src/lib/crawler-policy.ts` (real, current code)**

Before (as shipped):

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

The *what* is clear — a list of allowed user agents. The *why* isn't: the trailing `{ userAgent: '*', allow: '/' }` already allows everyone, which makes the three AI-crawler entries functionally redundant. A future editor can't tell whether those entries encode a real decision (explicitly welcome AI answer engines for visibility) or are dead weight nobody noticed. "Looks safe to delete" and "is safe to delete" are different claims, and the code doesn't let a reader tell them apart.

After (suggested — illustrative, not a claim this shipped):

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

One comment turns "delete this, it's redundant" from a plausible cleanup PR into a decision someone has to consciously reverse.

---

## 2. 추상화 비용 (Abstraction cost)

**Question:** Does this abstraction earn back more than it costs?

**Checklist:**
- If this layer were deleted, would the call sites actually get more complex, or just shorter by one hop?
- Does this abstraction prevent a specific, named bug or incident — or is it "might need it later"?
- Is there only one implementation today, while the interface is already shaped for several (YAGNI)?
- How many files does a reader cross to understand this layer — and is that cost paid every time, not just once?
- Do the call sites actually need different behavior, or do they just happen to share code twice?

**Example — `kalyx/packages/adapter-date-fns/src/index.ts` + `kalyx/packages/core/src/types.ts` (real, current code)**

`@kalyx/core` defines a `DateAdapter` interface (`parse`, `format`, `addDays`, `isBefore`, `today`, …) that three separate packages implement (`adapter-date-fns`, `adapter-luxon`, `adapter-dayjs`). That's real indirection — every date operation in the picker components goes through this interface instead of calling a date library directly.

Before (hypothetical — what calling the underlying library directly would look like without the adapter):

```ts
// 예시 (가상) — DateAdapter 없이 date-fns 를 직접 호출했다면
import { addDays } from 'date-fns';

function nextCalendarDay(iso: string): string {
  return addDays(new Date(iso), 1).toISOString();
}
```

This looks like it saves a layer. It also inherits a real bug: `date-fns`'s `addDays` mutates the *local* date field. When a calendar grid iterates day-by-day across a DST transition, that drifts by an hour and duplicates or skips a UTC day for users in a DST-observing zone.

After (real, `kalyx/packages/adapter-date-fns/src/index.ts`):

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

The abstraction is doing real work here, not speculative work: it fixed a named bug, and `kalyx/packages/adapter-date-fns/src/__tests__/conformance.test.ts` runs a shared conformance suite (`runAdapterConformanceTests`) against all three adapter implementations, proving they agree — which is the actual payoff a multi-implementation interface is supposed to buy. `kalyx/packages/react/src/internal/defaultAdapter.ts` also makes the abstraction boundary explicit rather than accidental: the `headless` entry point never installs a default adapter and throws with a remediation hint if one isn't passed, instead of failing later with a cryptic error inside date math.

That's the shape of a lens-2 pass that concludes "cost justified" — the finding isn't a defect, it's evidence recorded for why the layer stays.

---

## 3. 상태의 위치 (State placement)

**Question:** Does state promoted to global/context actually need to live there?

**Checklist:**
- How many consumers read this state right now? One consumer is not a reason for a global store.
- Is "might reuse it later" the only justification given?
- If this were promoted, what happens on remount, back-navigation, or refresh — was that designed, or does the URL already solve it better?
- Is this reaching for context/global to dodge two or three levels of prop drilling, when drilling would be cheaper to read?
- Does one global slot bundle values with genuinely different lifetimes (e.g. session-scoped input mixed with page-navigation position)?

**Example — `jjan/apps/web/app/calculators/commute/commute-flow.tsx` + `draft.ts` (real, current code)**

Before (hypothetical — promoting the draft to a global store "for future reuse"):

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

Only one screen ever reads this. Promoting it buys nothing today, and it costs a new place for state to outlive the component that's supposed to own it — surviving navigation in ways nobody designed for.

After (real, `jjan/apps/web/app/calculators/commute/commute-flow.tsx`):

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

Two different kinds of state get two different, deliberately *not*-global homes: step position lives in the URL (`?step=n`, so back/forward and refresh behave for free), and form input lives in component state with a session-storage mirror (`draft-storage.ts`) for reload survival — not a store, and explicitly not sent to the server. The comment states the promotion rule as policy ("no global store until there's a second consumer"), which is exactly what this lens is checking for.

---

## 4. 인터페이스 예측가능성 (Interface predictability)

**Question:** Do the name and signature match what the code actually does?

**Checklist:**
- Does the verb in the function name cover everything it actually does — could a caller guess the side effects from the name alone?
- Does the return type hide a failure, empty, or partial-value case?
- Does the same-named function change different fields depending on hidden internal state that isn't in the signature?
- Does argument order/shape break the convention nearby functions use (callback first here, last there)?
- Does the JSDoc have to explain behavior the signature alone can't convey — if so, that's evidence the name/signature is doing too little?

**Example — `kalyx/packages/react/src/hooks/useRangePicker.ts` (real, current code)**

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
      // ... may swap start/end via adapter.isBefore
      if (!setRange(newRange)) return;
      setSelectingTarget('start');
      setHoverDate(null);
      setIsOpen(false); // only on this branch
    }
  },
  [selectingTarget, currentValue.start, adapter, setRange, displayTimezone],
);
```

The signature `selectDate: (iso: ISODateString) => void` promises the same thing on every call. It isn't: which field changes (`start` vs `end`), whether the two dates get swapped (`adapter.isBefore` reorders them), and whether the popover closes, all depend on the hidden `selectingTarget` field — which the type never exposes. `useRangePicker` is documented as the hook to reach for when building a fully custom UI, so a caller wiring their own popover open/close logic around it has no way to predict from name + signature alone that calling `selectDate(iso)` will sometimes close their popover out from under them.

After (suggested — illustrative; the public API name doesn't have to change, but the contract should stop hiding in the implementation):

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

Nothing in the implementation has to change for this fix — only the contract a reader sees before opening the source file.

---

## 5. 비동기 UX (Async UX)

**Question:** Are loading, error, and empty states designed, not incidental?

**Checklist:**
- If loading runs long (1s+), does the user get a different signal, or the same silent spinner the whole time?
- Are offline/network failure and server errors (4xx/5xx) collapsed into the same screen?
- Does retry after failure preserve the user's input, or reset the form?
- Is there a guard against a slow first request resolving after a faster second one, overwriting the screen with stale data?
- Are "empty result," "not yet loaded," and "failed to load" visibly different states, or all rendered the same way?

**Example — `jjan/apps/web/app/calculators/commute/use-calculation.ts` + `calculation-error.tsx` (real, current code)**

Before (hypothetical — a common shape this lens exists to catch):

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

No distinction between "still fast" and "taking a while." Offline and a 503 both become the same generic string. Nothing stops a slow first `run()` from resolving after a second one and clobbering its result. Retrying just re-runs the same function with whatever the form currently holds — nothing guarantees the input wasn't cleared first.

After (real, `jjan/apps/web/app/calculators/commute/use-calculation.ts`):

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

The hook tracks a `requestId` and only commits a settled response if it's still current — a slow first request can never overwrite a faster second one. A `setTimeout` at `SLOW_NOTICE_AFTER_MS` (1000ms) flips `loading.slow` so a long wait gets a progress message instead of a silent spinner. `calculation-error.tsx` renders offline, "unavailable" (with a `retryAfterSeconds`-aware message and no retry button, since retrying a maintenance window just repeats the failure), and generic failures as distinct views, all stacked over the still-filled form — never clearing input — with an explicit line telling the user so ("입력한 내용은 그대로 남아 있어요"), and a comment recording the decision not to use a toast ("사라지면 무엇이 잘못됐는지 다시 볼 수 없다").

---

## 6. 숨은 동작 (Hidden side effects)

**Question:** Are there side effects the caller can't see from the call site?

**Checklist:**
- Does the function silently read something it wasn't passed (current time, randomness, global config) and let that change the result?
- Does the name of the return value imply "raw/as-is" when it's actually adjusted or computed?
- Does one call trigger unexpected extra work — logging, a cache write, an external call — beyond what the name suggests?
- Is there any evidence (a comment, a type, a test) that callers actually know about this behavior?
- Does calling this twice with the same input give different results for a reason that isn't in the signature?

**Example — `jihoon-blog/src/lib/google-analytics.ts` + `daily-visitor-baseline.ts` (real, current code)**

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

`AnalyticsStats.todayVisitors` reads like "today's real visitor count, straight from GA." It isn't: every call silently adds a date-seeded offset (10–40, deterministic per calendar day) before returning. The type is `number`; nothing at the call site (`AnalyticsStats.tsx`, the component that renders this) marks it as adjusted. Whichever reason this exists for — plausibly not exposing a literal "1 visitor today," which could let a specific reader deduce they were that visitor — that reasoning lives nowhere near the function that applies it, and nowhere near its caller either.

After (suggested — illustrative; documents the adjustment where the type is declared, next to where a caller would actually look):

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

The fix isn't removing the behavior — it's making it visible at the one place a future caller is guaranteed to look.

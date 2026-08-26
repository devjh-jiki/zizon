# CONTEXT.md 포맷

## 구조

```md
# {컨텍스트 이름}

{이 컨텍스트가 무엇이고 왜 존재하는지 한두 문장 설명.}

## Language

**Order**:
{용어에 대한 한두 문장 설명}
_Avoid_: Purchase, transaction

**Invoice**:
배송 후 고객에게 보내는 결제 요청.
_Avoid_: Bill, payment request

**Customer**:
주문을 넣는 사람 또는 조직.
_Avoid_: Client, buyer, account
```

## 규칙

- **단호하게.** 같은 개념에 여러 단어가 있으면 가장 좋은 하나를 고르고 나머지는 `_Avoid_` 아래 나열한다.
- **조건부 avoid 도 괜찮다.** 한 단어가 한 용어엔 맞고 다른 용어엔 틀릴 때(예: "cancel"은 Subscription 을 끝내는 것이지 Order 를 무르는 게 아니다) 조건을 단다: `_Avoid_: cancel (Order 를 뜻할 때)`. 평평한 동의어 목록은 overload 를 표현 못 한다; 조건부는 한다.
- **정의는 빡빡하게.** 최대 한두 문장. 무엇을 *하는지*가 아니라 무엇*인지*를 정의한다.
- **역할(role)과 이벤트(event)도 유효한 항목**이다, 엔티티만이 아니라. 역할("Owner — Account 의 결제를 책임지는 User; 재할당 가능한 역할")이나 도메인 이벤트("PaymentFailed — Account 에 대한 청구가 성공하지 못했음을 알리는 도메인 이벤트")는 그 *이름과 의미*가 프로젝트 고유일 때 여기 들어간다. 이벤트의 전달 메커니즘은 안 들어간다 — 그건 ADR 이나 Decisions 목록 항목이다.
- **이 프로젝트 컨텍스트에 고유한 용어만 포함.** 일반적인 프로그래밍 개념(타임아웃, 에러 타입, 유틸리티 패턴)은 프로젝트가 아무리 많이 써도 여기 들어가지 않는다. 용어를 추가하기 전에 묻는다: 이게 이 컨텍스트에 고유한 개념인가, 아니면 일반 프로그래밍 개념인가? 전자만 들어간다.
- **자연스러운 묶음이 생기면 소제목 아래로 그룹화한다.** 모든 용어가 하나의 응집된 영역에 속하면 평평한 목록이어도 괜찮다.

## 선택적 `## Decisions` 섹션

`CONTEXT.md` 는 `## Language` 용어집 *아래에* ADR 까지는 아닌 정해졌지만 되돌릴 수 있는 선택(튜닝 가능한 정책, 기본값, 관례)을 위한 짧은 `## Decisions` 목록을 둘 수 있다. 한 줄씩: 선택과 이유 몇 마디. 용어집과 시각적으로 분리한다 — `## Language` 는 용어만 정의하고, `## Decisions` 는 선택을 기록한다. 되돌리기 어려운 것은 ADR 로 졸업한다(ADR-FORMAT.md 참고).

```md
## Decisions

- 이메일 재시도 예산은 푸시보다 길다 (이메일은 덜 시간 민감).
- dead-letter 항목은 30일 보관, 수동 재생만 (오래된 OTP 자동 재생은 해롭다).
```

## 단일 vs 다중 컨텍스트 레포

**단일 컨텍스트(대부분의 레포):** 레포 루트에 `CONTEXT.md` 하나.

**다중 컨텍스트:** 레포 루트의 `CONTEXT-MAP.md` 가 컨텍스트들, 그 위치, 그리고 서로의 관계를 나열한다:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — 고객 주문을 받고 추적
- [Billing](./src/billing/CONTEXT.md) — 인보이스 생성 및 결제 처리
- [Fulfillment](./src/fulfillment/CONTEXT.md) — 창고 피킹 및 배송 관리

## Relationships

- **Ordering → Fulfillment**: Ordering 이 `OrderPlaced` 이벤트를 발행; Fulfillment 가 소비해 피킹 시작
- **Fulfillment → Billing**: Fulfillment 가 `ShipmentDispatched` 이벤트를 발행; Billing 이 소비해 인보이스 생성
- **Ordering ↔ Billing**: `CustomerId` 와 `Money` 공유 타입
```

스킬은 어떤 구조가 적용되는지 추론한다:

- `CONTEXT-MAP.md` 가 있으면 읽어서 컨텍스트들을 찾는다
- 루트 `CONTEXT.md` 만 있으면 단일 컨텍스트
- 둘 다 없으면 첫 용어가 정리될 때 루트 `CONTEXT.md` 를 게으르게 만든다

다중 컨텍스트가 있으면 현재 주제가 어느 컨텍스트와 관련되는지 추론한다. 불분명하면 묻는다.

---
name: article-writing
description: Use when drafting long-form content meant to persuade or teach a reader — blog posts, essays, launch posts, guides, tutorials, newsletter issues, conference talk write-ups — or when turning notes, transcripts, and research into a polished piece, or when tightening the structure, pacing, and evidence of long-form copy that already exists. Korean triggers 블로그 글, 글 써줘, 아티클, 뉴스레터, 발표 원고, 초안 다듬어줘, 글이 밋밋해, "AI 가 쓴 티가 나". NOT for internal domain or wiki documents (use writing-domain-docs), NOT for marketing landing pages (use anti-slop-frontend), NOT for commit messages or PR descriptions.
---

# Article Writing

읽는 사람이 **관점을 가진 사람이 썼다고 느끼는 글**을 쓴다.
LLM 이 스스로를 문질러 반죽으로 만든 글이 아니라.

## 핵심 규칙 다섯

1. **구체적인 것부터 놓는다.** 결과물, 예시, 산출값, 일화, 숫자, 스크린샷, 코드
2. **설명은 예시 뒤에 온다.** 앞에 두면 독자가 뭘 이해해야 하는지 모른 채 정의를 읽는다
3. **문장을 짧게 유지한다.** 원본 목소리가 의도적으로 길지 않은 한
4. **형용사 대신 증거를 쓴다.** "혁신적인" 대신 그것이 무엇을 바꿨는지
5. **사실·신뢰·고객 사례를 지어내지 않는다.** 하나라도 지어내면 글 전체가 무너진다

## 쓰는 순서

1. 독자와 목적을 정한다
2. **한 섹션에 한 가지 일**을 주는 단단한 개요를 만든다
3. 각 섹션을 증거·결과물·갈등·예시로 연다
4. 다음 문장이 자리값을 할 때만 늘린다
5. 템플릿 같거나, 과설명이거나, 자기만족적인 것을 잘라낸다

## 글 종류별

**기술 가이드**
- 독자가 무엇을 얻는지로 연다
- 주요 섹션마다 코드·명령·스크린샷·실제 출력을 넣는다
- 부드러운 요약이 아니라 **실행 가능한 것**으로 끝낸다

**에세이 · 의견**
- 긴장, 모순, 구체적 관찰로 연다
- 섹션당 논지 하나
- 의견이 증거에 답하게 한다

**뉴스레터**
- 첫 화면이 실제로 일하게 한다
- 일기 같은 도입부를 앞에 두지 않는다
- 섹션 라벨은 훑기 쉬워질 때만 쓴다

## 지우고 다시 쓸 것

**영어권 상투구**
- "In today's rapidly evolving landscape"
- "game-changer", "cutting-edge", "revolutionary"
- 다리 역할만 하는 "here's why this matters"
- 꾸며낸 취약함 서사
- 참여를 끌려고 붙인 마무리 질문
- 논지를 밀지 않는 자기소개 늘리기
- 본론을 미루는 AI 특유의 목 가다듬기

**한국어 상투구**
- "바야흐로", "~의 시대가 도래했다", "화두로 떠오르고 있다"
- "~라고 할 수 있다", "~인 것 같다" — 주장을 흐리는 완충어
- "~에 대해", "~를 통해", "~에 있어서" — 번역투
- "필자는", "여러분은 어떠신가요?"
- 마지막 문단의 소감·다짐·전망 3종 세트

## 목소리

특정 목소리를 원하면 **brand-voice** 를 먼저 돌리고 그 `VOICE PROFILE` 을 재사용한다.
여기서 문체 분석을 한 번 더 하지 않는다 — 사용자가 명시적으로 요청할 때만.

참조가 없으면 기본값은 **날 선 실무자 목소리**다: 구체적이고, 감상적이지 않고, 쓸모 있게.

## 내보내기 전 관문

- [ ] 사실 주장마다 제공된 출처가 뒤에 있는가
- [ ] 일반적인 AI 전환 문구가 사라졌는가
- [ ] 목소리가 제시된 예시 또는 합의된 `VOICE PROFILE` 과 맞는가
- [ ] **모든 섹션이 새로운 것을 더하는가** — 하나라도 아니면 지운다
- [ ] 형식이 실릴 매체에 맞는가
- [ ] 첫 문단과 마지막 문단이 둘 다 정보를 나르는가

## 함께 쓰는 스킬

- 내부 도메인 문서·위키는 **writing-domain-docs**
- 문서 세트의 역할 분리는 **living-docs-governance**
- 문체 프로필 추출은 **brand-voice**

## Attribution

Adapted from [affaan-m/ecc `article-writing`](https://github.com/affaan-m/ecc) (MIT).
핵심 규칙 다섯, 쓰는 순서, 글 종류별 구조, 영어권 금지 패턴, 목소리 처리, 내보내기 관문을
보존했다. 이 저장소용으로 한국어화하고, 한국어 상투구 목록과 자매 스킬 링크를 더했다.
THIRD_PARTY_NOTICES.md 참조.

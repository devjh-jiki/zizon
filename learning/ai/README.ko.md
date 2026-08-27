# AI 학습 로드맵 (프론트엔드 개발자용)

> English: [README.md](./README.md)

프론트엔드 개발자로서 AI를 **실무에 활용**하는 것을 1차 목표로, 내부 원리는 선택 심화로 둔 학습 로드맵입니다.
전달받은 자료를 분류하고 단계별 순서로 재구성했습니다.

- 실습 기록: [`journal.md`](./journal.ko.md)
- 실습 코드: `ai-playground` 레포

---

## 1. 프론트엔드 개발자가 우선 얻을 것 (실무 직결순)

1. **프롬프트 엔지니어링** — LLM 호출 품질 결정. UI에서 LLM 쓸 때 필수
2. **에이전트 / 도구 호출** — AI 기능을 프론트에 붙이는 아키텍처
3. **MCP** — 에디터/앱에 도구 연결 (MCP 모음집과 직결)
4. **벡터DB / 임베딩** — RAG, 검색 기능 구현
5. **에이전트 메모리** — 대화형 UI 상태 관리

---

## 2. 단계별 학습 순서

> 단계 5까지가 프론트엔드 실무의 ~80%. 6은 깊이 파고 싶을 때 + 블로그 소재.

### 단계 0 — 개념 잡기

- LLM Introduction (영상)
- Awesome Generative AI Guide
- **산출물**: 용어 정리 노트

### 단계 1 — 활용 기초 (프롬프트)

- Prompt Engineering Guide
- Chain-of-Thought Prompting (논문)
- **산출물**: 프롬프트 패턴 모음 → [`prompts/`](../../prompts/README.ko.md) 에 반영

### 단계 2 — 첫 통합 (앱에서 LLM 호출)

- OpenAI's Practical Guide to Building Agents
- Building Effective Agents (Anthropic)
- **산출물**: 간단한 챗 UI (ai-playground)

### 단계 3 — 에이전트 (도구 호출 / 루프)

- Building an Agent from Scratch (영상)
- ReAct (논문), Toolformer (논문)
- HuggingFace Agent Course
- Microsoft AI Agents for Beginners
- **산출물**: 도구를 쓰는 에이전트

### 단계 4 — MCP (도구 표준 연결)

- Building Agents with MCP (영상)
- MCP with Anthropic (코스)
- AI Agents with MCP — Kyle Stratis (책)
- **산출물**: MCP 서버 1개

### 단계 5 — RAG / 메모리

- Building Vector Databases with Pinecone
- Vector Databases: from Embeddings to Applications
- Agent Memory (코스)
- **산출물**: RAG 데모

### 단계 6 — 심화 (선택, 블로그 소재)

- LLMs from Scratch / Building an LLM from Scratch (책·영상)
- Understanding Deep Learning (책)
- AI Engineering (책)
- The LLM Engineering Handbook (책)
- Designing Machine Learning Systems (책)
- **산출물**: 기술 블로그 글

---

## 3. 전달받은 자료 전체 분류

### Videos
- LLM Introduction → 단계 0
- LLMs from Scratch → 단계 6
- Agentic AI Overview (Stanford) → 단계 2~3
- Building and Evaluating Agents → 단계 3
- Building Effective Agents → 단계 2
- Building Agents with MCP → 단계 4
- Building an Agent from Scratch → 단계 3
- Philo Agents → 단계 3

### Repos
- GenAI Agents → 단계 3 (실습)
- Microsoft's AI Agents for Beginners → 단계 3
- Prompt Engineering Guide → 단계 1
- Hands-On Large Language Models → 단계 2~6
- Made with ML → 단계 2~5 (MLOps 관점)
- Hands-On AI Engineering → 단계 2~5
- Awesome Generative AI Guide → 단계 0 (인덱스)
- Designing Machine Learning Systems → 단계 6
- Machine Learning for Beginners (Microsoft) → 단계 0~1
- LLM Course → 단계 1~3

### Guides
- Google's Agent Whitepaper / Agent Companion → 단계 3
- Building Effective Agents (Anthropic) → 단계 2 ★ 강추
- Claude Code Best Agentic Coding Practices → 단계 2~4 ★ 실무 직결
- OpenAI's Practical Guide to Building Agents → 단계 2 ★ 강추

### Books
- Understanding Deep Learning → 단계 6
- Building an LLM from Scratch → 단계 6
- The LLM Engineering Handbook → 단계 6
- AI Agents: The Definitive Guide (Nicole Koenigstein) → 단계 3
- Building Applications with AI Agents (Michael Albada) → 단계 3~5
- AI Agents with MCP (Kyle Stratis) → 단계 4
- AI Engineering → 단계 6

### Papers
- ReAct → 단계 3 ★ 에이전트 핵심
- Generative Agents → 단계 3~5
- Toolformer → 단계 3
- Chain-of-Thought Prompting → 단계 1 ★ 프롬프트 핵심

### Courses
- HuggingFace's Agent Course → 단계 3
- MCP with Anthropic → 단계 4
- Building Vector Databases with Pinecone → 단계 5
- Vector Databases from Embeddings to Apps → 단계 5
- Agent Memory → 단계 5

> 원본 단축 URL(t.co)은 깨질 수 있으니, 각 자료를 실제로 열 때 정식 URL로 교체해 두세요.

---

## 4. 추가로 모으면 좋은 자료 (목록에 빠진 것)

프론트엔드 실무에 특히 유용한데 원본 목록에 없던 것들:

- **Vercel AI SDK 문서** — 프론트에서 가장 실용적인 LLM 통합 라이브러리 ★ 최우선 추천
- **Anthropic Cookbook / OpenAI Cookbook** — 실전 코드 레시피
- **LangChain JS / LlamaIndex TS 문서** — RAG 구현
- **patterns.dev** — 프론트엔드 아키텍처 패턴
- **MCP 공식 문서** (modelcontextprotocol.io) — 단계 4 레퍼런스

---

## 5. 학습 운영 방식

- 각 단계마다 **읽기 → 작은 실습 → 기록** 사이클.
- 실습은 `ai-playground` 레포에 단계별 폴더로.
- 기록은 [`journal.md`](./journal.ko.md) 에 날짜별로. 블로그감이 되면 글로 작성.

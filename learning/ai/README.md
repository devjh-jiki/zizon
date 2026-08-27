# AI Learning Roadmap (for Frontend Developers)

> 한국어: [README.ko.md](./README.ko.md)

A learning roadmap whose primary goal is to **apply AI in practice** as a frontend developer, with internal mechanics left as optional deep dives.
The provided materials are categorized and reorganized into a stage-by-stage sequence.

- Practice log: [`journal.md`](./journal.md)
- Practice code: `ai-playground` repo

---

## 1. What a frontend developer should get first (ordered by practical relevance)

1. **Prompt engineering** — Determines LLM call quality. Essential when using LLMs in the UI
2. **Agents / tool calling** — Architecture for attaching AI features to the frontend
3. **MCP** — Connecting tools to editors/apps (directly tied to the MCP collection)
4. **Vector DB / embeddings** — Implementing RAG and search features
5. **Agent memory** — State management for conversational UIs

---

## 2. Stage-by-stage learning order

> Through Stage 5 covers ~80% of frontend practice. Stage 6 is for when you want to go deep + blog material.

### Stage 0 — Grasp the concepts

- LLM Introduction (video)
- Awesome Generative AI Guide
- **Output**: terminology notes

### Stage 1 — Application basics (prompts)

- Prompt Engineering Guide
- Chain-of-Thought Prompting (paper)
- **Output**: a collection of prompt patterns → reflected in [`prompts/`](../../prompts)

### Stage 2 — First integration (calling an LLM from an app)

- OpenAI's Practical Guide to Building Agents
- Building Effective Agents (Anthropic)
- **Output**: a simple chat UI (ai-playground)

### Stage 3 — Agents (tool calling / loop)

- Building an Agent from Scratch (video)
- ReAct (paper), Toolformer (paper)
- HuggingFace Agent Course
- Microsoft AI Agents for Beginners
- **Output**: an agent that uses tools

### Stage 4 — MCP (standard tool connection)

- Building Agents with MCP (video)
- MCP with Anthropic (course)
- AI Agents with MCP — Kyle Stratis (book)
- **Output**: one MCP server

### Stage 5 — RAG / memory

- Building Vector Databases with Pinecone
- Vector Databases: from Embeddings to Applications
- Agent Memory (course)
- **Output**: a RAG demo

### Stage 6 — Deep dive (optional, blog material)

- LLMs from Scratch / Building an LLM from Scratch (book·video)
- Understanding Deep Learning (book)
- AI Engineering (book)
- The LLM Engineering Handbook (book)
- Designing Machine Learning Systems (book)
- **Output**: a technical blog post

---

## 3. Full categorization of provided materials

### Videos
- LLM Introduction → Stage 0
- LLMs from Scratch → Stage 6
- Agentic AI Overview (Stanford) → Stage 2~3
- Building and Evaluating Agents → Stage 3
- Building Effective Agents → Stage 2
- Building Agents with MCP → Stage 4
- Building an Agent from Scratch → Stage 3
- Philo Agents → Stage 3

### Repos
- GenAI Agents → Stage 3 (practice)
- Microsoft's AI Agents for Beginners → Stage 3
- Prompt Engineering Guide → Stage 1
- Hands-On Large Language Models → Stage 2~6
- Made with ML → Stage 2~5 (MLOps perspective)
- Hands-On AI Engineering → Stage 2~5
- Awesome Generative AI Guide → Stage 0 (index)
- Designing Machine Learning Systems → Stage 6
- Machine Learning for Beginners (Microsoft) → Stage 0~1
- LLM Course → Stage 1~3

### Guides
- Google's Agent Whitepaper / Agent Companion → Stage 3
- Building Effective Agents (Anthropic) → Stage 2 ★ highly recommended
- Claude Code Best Agentic Coding Practices → Stage 2~4 ★ directly practical
- OpenAI's Practical Guide to Building Agents → Stage 2 ★ highly recommended

### Books
- Understanding Deep Learning → Stage 6
- Building an LLM from Scratch → Stage 6
- The LLM Engineering Handbook → Stage 6
- AI Agents: The Definitive Guide (Nicole Koenigstein) → Stage 3
- Building Applications with AI Agents (Michael Albada) → Stage 3~5
- AI Agents with MCP (Kyle Stratis) → Stage 4
- AI Engineering → Stage 6

### Papers
- ReAct → Stage 3 ★ agent core
- Generative Agents → Stage 3~5
- Toolformer → Stage 3
- Chain-of-Thought Prompting → Stage 1 ★ prompt core

### Courses
- HuggingFace's Agent Course → Stage 3
- MCP with Anthropic → Stage 4
- Building Vector Databases with Pinecone → Stage 5
- Vector Databases from Embeddings to Apps → Stage 5
- Agent Memory → Stage 5

> Original shortened URLs (t.co) may break, so replace each with the canonical URL when you actually open the material.

---

## 4. Materials worth collecting (missing from the list)

Things especially useful for frontend practice that were not in the original list:

- **Vercel AI SDK docs** — The most practical LLM integration library for the frontend ★ top recommendation
- **Anthropic Cookbook / OpenAI Cookbook** — Real-world code recipes
- **LangChain JS / LlamaIndex TS docs** — RAG implementation
- **patterns.dev** — Frontend architecture patterns
- **MCP official docs** (modelcontextprotocol.io) — Stage 4 reference

---

## 5. How learning is run

- A **read → small practice → log** cycle for each stage.
- Practice goes into the `ai-playground` repo in per-stage folders.
- Logging goes into [`journal.md`](./journal.md) by date. When something is blog-worthy, write it up as a post.

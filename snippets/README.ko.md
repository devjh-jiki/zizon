# Snippets

> English: [README.md](./README.md)

자주 쓰는 코드/설정 스니펫 모음. (eslint, tsconfig, CI 설정 등)

| 파일 | 용도 |
|------|------|
| [`discord-notify.mjs`](./discord-notify.mjs) | 디스코드 Webhook 알림 공용 모듈 (text + embed) |
| [`figma-mcp-node-relay.cjs`](./figma-mcp-node-relay.cjs) | `claude-talk-to-figma-mcp` 의 Bun 전용 WebSocket 릴레이를 Node 로 포팅한 것 |

## discord-notify.mjs

여러 프로젝트(뉴스레터, 토스 매매 리포트, 향후 알람)에서 재사용하는 디스코드 알림 함수.
의존성 없음 (Node 18+ 내장 `fetch`).

### 준비

디스코드에서 채널별 Webhook URL을 만들고 환경변수로 둡니다 (URL은 비밀로 취급):

```
DISCORD_WEBHOOK_NEWSLETTER=https://discord.com/api/webhooks/.../...
DISCORD_WEBHOOK_TOSS=https://discord.com/api/webhooks/.../...
DISCORD_WEBHOOK_ALARMS=https://discord.com/api/webhooks/.../...
```

> Webhook 생성: 채널 우클릭 → 채널 편집 → 연동 → 웹후크 → 새 웹후크 → URL 복사

### 사용

```js
import { sendDiscord, sendDiscordEmbed } from "./discord-notify.mjs";

// 1) 단순 텍스트
await sendDiscord(process.env.DISCORD_WEBHOOK_NEWSLETTER, "오늘의 뉴스레터가 도착했습니다 📰");

// 2) 카드형(embed)
await sendDiscordEmbed(process.env.DISCORD_WEBHOOK_TOSS, {
  title: "📈 토스 매매 리포트",
  description: "오늘 3건 체결",
  color: 0x2ecc71, // 초록
  fields: [
    { name: "수익률", value: "+1.2%", inline: true },
    { name: "체결", value: "3건", inline: true },
  ],
  url: "https://github.com/devjh-jiki/...",
});
```

### 재사용 방법

- 작은 프로젝트: 이 파일을 복사해 넣고 쓰기
- 또는 각 레포에서 raw URL로 가져와 쓰기

색상 참고: `0x5865F2`(디스코드 블루), `0x2ecc71`(초록/수익), `0xe74c3c`(빨강/손실), `0xf1c40f`(노랑/경고).

## figma-mcp-node-relay.cjs

`claude-talk-to-figma-mcp`(`arinspunk/claude-talk-to-figma-mcp`)는 소켓 서버를 `dist/socket.js` 로 배포하는데
Bun 이 필요하다. 이 머신에 bun 이 없어서 그 파일을 Node 로 포팅한 것이다.

프로토콜과 로직은 원본과 같다. 채널 join, 채널당 직렬 명령 큐, 플러그인 응답 unicast,
`progress_update` 전달, stale request 정리.

### 왜 여기 두는가

원래는 남의 레포 클론 안에 untracked 로 있었다. 재클론하거나 그 폴더를 지우면 사라진다.
upstream 은 우리 것이 아니라 그쪽에 커밋해도 푸시할 곳이 없다.

### 사용

```sh
npm i ws          # 유일한 의존성
node figma-mcp-node-relay.cjs
```

그 다음 Figma 플러그인과 MCP 서버를 원본 릴레이와 같은 채널로 맞춘다.
나중에 bun 을 설치하면 upstream 의 `dist/socket.js` 를 쓰면 되고 이 파일은 필요 없어진다.

# Snippets

> 한국어: [README.ko.md](./README.ko.md)

A collection of frequently used code/config snippets. (eslint, tsconfig, CI configs, etc.)

| File | Purpose |
|------|------|
| [`discord-notify.mjs`](./discord-notify.mjs) | Shared Discord Webhook notification module (text + embed) |
| [`figma-mcp-node-relay.cjs`](./figma-mcp-node-relay.cjs) | Node port of the Bun-only WebSocket relay in `claude-talk-to-figma-mcp` |

## discord-notify.mjs

A Discord notification function reused across multiple projects (newsletter, Toss trading report, future alarms).
No dependencies (uses Node 18+ built-in `fetch`).

### Setup

Create a per-channel Webhook URL in Discord and store it as an environment variable (treat the URL as a secret):

```
DISCORD_WEBHOOK_NEWSLETTER=https://discord.com/api/webhooks/.../...
DISCORD_WEBHOOK_TOSS=https://discord.com/api/webhooks/.../...
DISCORD_WEBHOOK_ALARMS=https://discord.com/api/webhooks/.../...
```

> Create a Webhook: right-click channel → Edit Channel → Integrations → Webhooks → New Webhook → Copy URL

### Usage

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

### How to reuse

- Small projects: copy this file in and use it
- Or pull it via raw URL from each repo

Color reference: `0x5865F2` (Discord blue), `0x2ecc71` (green/profit), `0xe74c3c` (red/loss), `0xf1c40f` (yellow/warning).

## figma-mcp-node-relay.cjs

`claude-talk-to-figma-mcp` (`arinspunk/claude-talk-to-figma-mcp`) ships its socket server as `dist/socket.js`,
which requires Bun. This is a Node port of that file, kept because bun is not installed on this machine.

Protocol and logic match the original: channel join, per-channel serialized command queue,
unicast plugin responses, `progress_update` relay, stale request cleanup.

### Why it lives here

It was an untracked file inside a third-party clone, so re-cloning or deleting that folder would lose it.
The upstream repo is not ours, so committing it there has nowhere to push.

### Usage

```sh
npm i ws          # only dependency
node figma-mcp-node-relay.cjs
```

Then point the Figma plugin and the MCP server at the same channel as with the original relay.
If bun ever gets installed, use the upstream `dist/socket.js` instead and this file becomes unnecessary.

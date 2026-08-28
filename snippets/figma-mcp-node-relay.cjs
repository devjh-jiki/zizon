// claude-talk-to-figma-mcp v1.0.0 dist/socket.js 의 Node 포팅.
// 원본은 Bun.serve 전용이라 이 머신(bun 미설치)에서 실행 불가.
// 로직·프로토콜은 원본과 동일하게 유지: 채널 join / 명령 큐(채널당 직렬) /
// 플러그인 응답 unicast / progress_update 전달 / stale request 정리.
const http = require('http');
const { WebSocketServer, WebSocket } = require('ws');

const logger = {
  info: (m, ...a) => console.log(`[INFO] ${m}`, ...a),
  debug: (m, ...a) => console.log(`[DEBUG] ${m}`, ...a),
  warn: (m, ...a) => console.warn(`[WARN] ${m}`, ...a),
  error: (m, ...a) => console.error(`[ERROR] ${m}`, ...a),
};

const channels = new Map();
const stats = {
  totalConnections: 0, activeConnections: 0, messagesSent: 0, messagesReceived: 0, errors: 0,
  queueDepthMax: 0, queuedCommands: 0, queueRejections: 0, blockedCommands: 0,
  unicastResponses: 0, discardedResponses: 0, cleanedStaleRequests: 0,
};
const requestToClient = new Map();
const pluginClients = new Set();
const agentClients = new Set();
const sessionToClient = new Map();

const CREATION_COMMANDS = new Set([
  'create_rectangle', 'create_frame', 'create_text', 'create_ellipse', 'create_polygon',
  'create_star', 'create_vector', 'create_line', 'create_component_instance',
  'create_component_set', 'set_svg', 'clone_node', 'create_component_from_node',
  'create_section', 'create_sticky', 'create_shape_with_text', 'create_connector',
]);
const BLOCKED_COMMANDS = new Set(['set_current_page']);
const COMMAND_TIMEOUT_MS = 120000;
const channelQueues = new Map();
const MAX_QUEUE_SIZE = 100;

function getPluginClient(channelName) {
  const clients = channels.get(channelName);
  if (!clients) return null;
  for (const client of clients) if (pluginClients.has(client)) return client;
  return null;
}

function validateCommand(data) {
  const command = data.message?.command;
  const params = data.message?.params;
  if (BLOCKED_COMMANDS.has(command)) {
    return `"${command}" is a stateful command and is not allowed through the relay server. Instead, use the parentId parameter on creation commands to target a specific page or frame. Call get_pages to discover page node IDs, then pass the desired page ID as parentId.`;
  }
  if (CREATION_COMMANDS.has(command) && !params?.parentId) {
    return `"${command}" requires a parentId parameter. Pass the target page or frame node ID as parentId to specify where the element should be created. Call get_pages to discover available page IDs.`;
  }
  return null;
}

function classifyClient(ws, data) {
  if (pluginClients.has(ws) || agentClients.has(ws)) return;
  if (data.message?.result !== undefined || data.message?.error !== undefined) {
    pluginClients.add(ws);
    logger.info(`Client ${ws.data?.clientId} classified as Figma plugin`);
    return;
  }
  if (data.message?.command) {
    agentClients.add(ws);
    logger.info(`Client ${ws.data?.clientId} classified as MCP agent`);
  }
}

function ensureQueueState(channelName) {
  if (!channelQueues.has(channelName)) channelQueues.set(channelName, { queue: [], isProcessing: false });
  return channelQueues.get(channelName);
}

function enqueueCommand(data, ws, channelName) {
  const requestId = data.message?.id;
  if (!requestId) { logger.warn('Command missing message.id, cannot queue'); return; }
  const queueState = ensureQueueState(channelName);
  if (queueState.queue.length >= MAX_QUEUE_SIZE) {
    ws.send(JSON.stringify({
      type: 'broadcast',
      message: { id: requestId, error: `Command queue is full (${MAX_QUEUE_SIZE} pending commands). Wait for existing commands to complete.` },
      sender: 'You', channel: channelName,
    }));
    stats.queueRejections++; stats.messagesSent++;
    return;
  }
  requestToClient.set(requestId, { ws, timestamp: Date.now() });
  queueState.queue.push({ data, senderWs: ws, requestId, enqueuedAt: Date.now() });
  stats.queuedCommands++;
  if (queueState.queue.length > stats.queueDepthMax) stats.queueDepthMax = queueState.queue.length;
  if (queueState.queue.length > 50) logger.warn(`Queue depth warning: ${queueState.queue.length} commands pending in channel ${channelName}`);
  processQueue(channelName);
}

function processQueue(channelName) {
  const queueState = channelQueues.get(channelName);
  if (!queueState || queueState.isProcessing || queueState.queue.length === 0) return;
  queueState.isProcessing = true;
  const item = queueState.queue.shift();
  const pluginClient = getPluginClient(channelName);
  const payload = JSON.stringify({ type: 'broadcast', message: item.data.message, sender: 'User', channel: channelName });
  let forwarded = false;
  if (pluginClient && pluginClient.readyState === WebSocket.OPEN) {
    try { pluginClient.send(payload); stats.messagesSent++; forwarded = true; }
    catch (e) { logger.error('Failed to forward command to plugin:', e); stats.errors++; }
  } else {
    const clients = channels.get(channelName);
    if (clients) {
      for (const client of clients) {
        if (!agentClients.has(client) && client.readyState === WebSocket.OPEN) {
          try { client.send(payload); stats.messagesSent++; forwarded = true; }
          catch (e) { logger.error('Failed to forward command to non-agent client:', e); }
        }
      }
    }
  }
  if (!forwarded) {
    logger.warn(`No plugin client in channel ${channelName}, rejecting queued command`);
    if (item.senderWs.readyState === WebSocket.OPEN) {
      item.senderWs.send(JSON.stringify({
        type: 'broadcast',
        message: { id: item.requestId, error: 'No Figma plugin connected to this channel' },
        sender: 'You', channel: channelName,
      }));
      stats.messagesSent++;
    }
    requestToClient.delete(item.requestId);
    queueState.isProcessing = false;
    setTimeout(() => processQueue(channelName), 0);
    return;
  }
  queueState.currentRequestId = item.requestId;
  queueState.currentCommandTimeout = setTimeout(() => {
    if (queueState.currentRequestId !== item.requestId) return;
    logger.warn(`Command ${item.requestId} timed out after ${COMMAND_TIMEOUT_MS}ms in channel ${channelName}`);
    const entry = requestToClient.get(item.requestId);
    if (entry && entry.ws.readyState === WebSocket.OPEN) {
      try {
        entry.ws.send(JSON.stringify({
          type: 'broadcast',
          message: { id: item.requestId, error: 'Command timed out waiting for Figma plugin response' },
          sender: 'User', channel: channelName,
        }));
        stats.messagesSent++;
      } catch (e) { logger.error('Failed to send timeout error:', e); }
    }
    requestToClient.delete(item.requestId);
    queueState.isProcessing = false;
    queueState.currentCommandTimeout = undefined;
    queueState.currentRequestId = undefined;
    processQueue(channelName);
  }, COMMAND_TIMEOUT_MS);
  if (item.senderWs.readyState === WebSocket.OPEN) {
    try {
      item.senderWs.send(JSON.stringify({ type: 'broadcast', message: item.data.message, sender: 'You', channel: channelName }));
      stats.messagesSent++;
    } catch (e) { logger.error('Failed to send command echo to sender:', e); }
  }
  queueState.queue.forEach((waiting, index) => {
    if (waiting.senderWs.readyState === WebSocket.OPEN) {
      try {
        waiting.senderWs.send(JSON.stringify({
          type: 'queue_position', id: waiting.requestId, position: index + 1, queueSize: queueState.queue.length,
          message: { data: { status: 'queued', progress: 0, message: `Queued at position ${index + 1} of ${queueState.queue.length}` } },
        }));
        stats.messagesSent++;
      } catch (e) { logger.error('Failed to send queue position update:', e); }
    }
  });
}

function handleResponseFromPlugin(data, channelName) {
  const responseId = data.message?.id;
  const entry = responseId ? requestToClient.get(responseId) : null;
  if (entry && entry.ws.readyState === WebSocket.OPEN) {
    try {
      entry.ws.send(JSON.stringify({ type: 'broadcast', message: data.message, sender: 'User', channel: channelName }));
      stats.unicastResponses++; stats.messagesSent++;
    } catch (e) { logger.error('Failed to unicast response:', e); stats.errors++; }
    requestToClient.delete(responseId);
  } else {
    if (responseId) { logger.info(`Discarding orphaned response for request ${responseId} (sender disconnected)`); requestToClient.delete(responseId); }
    else logger.info('Discarding untracked response (no request ID)');
    stats.discardedResponses++;
  }
  const queueState = channelQueues.get(channelName);
  if (queueState && responseId && responseId === queueState.currentRequestId) {
    if (queueState.currentCommandTimeout) { clearTimeout(queueState.currentCommandTimeout); queueState.currentCommandTimeout = undefined; }
    queueState.currentRequestId = undefined;
    queueState.isProcessing = false;
    processQueue(channelName);
  }
}

function cleanupClient(ws, clientChannels = []) {
  const isPlugin = pluginClients.has(ws);
  if (isPlugin) {
    const channelsToCheck = clientChannels.length > 0 ? clientChannels : Array.from(channelQueues.keys());
    for (const channelName of channelsToCheck) {
      const queueState = channelQueues.get(channelName);
      if (!queueState) continue;
      if (queueState.isProcessing && queueState.currentRequestId) {
        const requestId = queueState.currentRequestId;
        logger.warn(`Plugin disconnected while command ${requestId} was in-flight on channel ${channelName}`);
        if (queueState.currentCommandTimeout) { clearTimeout(queueState.currentCommandTimeout); queueState.currentCommandTimeout = undefined; }
        const entry = requestToClient.get(requestId);
        if (entry && entry.ws.readyState === WebSocket.OPEN) {
          try {
            entry.ws.send(JSON.stringify({
              type: 'broadcast',
              message: { id: requestId, error: 'Figma plugin disconnected while processing command' },
              sender: 'User', channel: channelName,
            }));
            stats.messagesSent++;
          } catch (e) { logger.error('Failed to send plugin disconnect error:', e); }
        }
        requestToClient.delete(requestId);
        queueState.isProcessing = false;
        queueState.currentRequestId = undefined;
        setTimeout(() => processQueue(channelName), 0);
      }
    }
  }
  if (!isPlugin) {
    for (const [requestId, entry] of requestToClient.entries()) {
      if (entry.ws === ws) requestToClient.delete(requestId);
    }
  }
  for (const [channelName, queueState] of channelQueues.entries()) {
    const before = queueState.queue.length;
    queueState.queue = queueState.queue.filter((item) => {
      if (item.senderWs === ws) {
        logger.info(`Removing queued command ${item.requestId} from disconnected client`);
        requestToClient.delete(item.requestId);
        return false;
      }
      return true;
    });
    const removed = before - queueState.queue.length;
    if (removed > 0) logger.info(`Cleaned up ${removed} queued commands from disconnected client in channel ${channelName}`);
  }
  agentClients.delete(ws);
  pluginClients.delete(ws);
}

setInterval(() => {
  const maxAge = 10 * 60 * 1000;
  const now = Date.now();
  let cleaned = 0;
  for (const [requestId, entry] of requestToClient.entries()) {
    if (now - entry.timestamp > maxAge) { requestToClient.delete(requestId); cleaned++; }
  }
  if (cleaned > 0) { stats.cleanedStaleRequests += cleaned; logger.warn(`Cleaned up ${cleaned} stale request entries (age > 10 min)`); }
}, 5 * 60 * 1000);

const PORT = 3055;
const httpServer = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
    res.end();
    return;
  }
  if (url.pathname === '/status') {
    res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
    res.end(JSON.stringify({
      status: 'running', uptime: process.uptime(), stats,
      queue: {
        channels: Array.from(channelQueues.entries()).map(([name, state]) => ({ channel: name, queueDepth: state.queue.length, isProcessing: state.isProcessing })),
        pendingRequests: requestToClient.size, agentCount: agentClients.size, pluginCount: pluginClients.size,
      },
    }));
    return;
  }
  res.writeHead(200, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
  res.end('Claude to Figma WebSocket server running (Node relay). Try connecting with a WebSocket client.');
});

const wss = new WebSocketServer({ server: httpServer });

wss.on('connection', (ws) => {
  stats.totalConnections++;
  stats.activeConnections++;
  const clientId = `client_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  ws.data = { clientId };
  logger.info(`New client connected: ${clientId}`);
  try {
    ws.send(JSON.stringify({ type: 'system', message: 'Please join a channel to start communicating with Figma' }));
  } catch (e) { logger.error(`Failed to send welcome message to client ${clientId}:`, e); stats.errors++; }

  ws.on('message', (raw) => {
    try {
      stats.messagesReceived++;
      const data = JSON.parse(raw.toString());
      if (data.type === 'join') {
        const channelName = data.channel;
        if (!channelName || typeof channelName !== 'string') {
          ws.send(JSON.stringify({ type: 'error', message: 'Channel name is required' }));
          stats.messagesSent++;
          return;
        }
        const sessionId = data.sessionId;
        if (sessionId && typeof sessionId === 'string') {
          const oldWs = sessionToClient.get(sessionId);
          if (oldWs && oldWs !== ws) {
            logger.info(`Session ${sessionId} reconnected (client ${clientId}). Closing stale connection.`);
            const oldChannels = [];
            channels.forEach((clients, ch) => { if (clients.has(oldWs)) oldChannels.push(ch); });
            channels.forEach((clients) => clients.delete(oldWs));
            cleanupClient(oldWs, oldChannels);
            try { oldWs.close(1000, 'Replaced by reconnecting session'); } catch {}
            stats.activeConnections--;
          }
          sessionToClient.set(sessionId, ws);
          ws.data.sessionId = sessionId;
        }
        if (!channels.has(channelName)) { logger.info(`Creating new channel: ${channelName}`); channels.set(channelName, new Set()); }
        const channelClients = channels.get(channelName);
        channelClients.add(ws);
        logger.info(`Client ${clientId} joined channel: ${channelName}`);
        try {
          ws.send(JSON.stringify({ type: 'system', message: `Joined channel: ${channelName}`, channel: channelName }));
          stats.messagesSent++;
          ws.send(JSON.stringify({ type: 'system', message: { id: data.id, result: 'Connected to channel: ' + channelName }, channel: channelName }));
          stats.messagesSent++;
        } catch (e) { logger.error(`Failed to send join confirmation to client ${clientId}:`, e); stats.errors++; }
        try {
          channelClients.forEach((client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({ type: 'system', message: 'A new client has joined the channel', channel: channelName }));
              stats.messagesSent++;
            }
          });
        } catch (e) { logger.error('Error notifying channel about new client:', e); stats.errors++; }
        return;
      }
      if (data.type === 'message') {
        const channelName = data.channel;
        if (!channelName || typeof channelName !== 'string') {
          ws.send(JSON.stringify({ type: 'error', message: 'Channel name is required' }));
          stats.messagesSent++;
          return;
        }
        const channelClients = channels.get(channelName);
        if (!channelClients || !channelClients.has(ws)) {
          ws.send(JSON.stringify({ type: 'error', message: 'You must join the channel first' }));
          stats.messagesSent++;
          return;
        }
        classifyClient(ws, data);
        const isCommand = !!data.message?.command;
        const isResponse = data.message?.result !== undefined || data.message?.error !== undefined;
        if (isResponse) { handleResponseFromPlugin(data, channelName); return; }
        if (isCommand) {
          const validationError = validateCommand(data);
          if (validationError) {
            ws.send(JSON.stringify({ type: 'broadcast', message: { id: data.message.id, error: validationError }, sender: 'You', channel: channelName }));
            stats.blockedCommands++; stats.messagesSent++;
            return;
          }
          enqueueCommand(data, ws, channelName);
          return;
        }
        try {
          channelClients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({ type: 'broadcast', message: data.message, sender: client === ws ? 'You' : 'User', channel: channelName }));
              stats.messagesSent++;
            }
          });
        } catch (e) { logger.error(`Error broadcasting message to channel ${channelName}:`, e); stats.errors++; }
      }
      if (data.type === 'progress_update') {
        const channelName = data.channel;
        if (!channelName || typeof channelName !== 'string') return;
        const channelClients = channels.get(channelName);
        if (!channelClients) return;
        const requestId = data.id;
        const entry = requestId ? requestToClient.get(requestId) : null;
        if (entry && entry.ws.readyState === WebSocket.OPEN) {
          try { entry.ws.send(JSON.stringify(data)); stats.messagesSent++; }
          catch (e) { logger.error('Failed to unicast progress update:', e); }
        } else {
          try {
            channelClients.forEach((client) => {
              if (client.readyState === WebSocket.OPEN) { client.send(JSON.stringify(data)); stats.messagesSent++; }
            });
          } catch (e) { logger.error('Error broadcasting progress update:', e); stats.errors++; }
        }
      }
    } catch (err) {
      stats.errors++;
      logger.error('Error handling message:', err);
      try {
        ws.send(JSON.stringify({ type: 'error', message: 'Error processing your message: ' + (err instanceof Error ? err.message : String(err)) }));
        stats.messagesSent++;
      } catch (sendError) { logger.error('Failed to send error message to client:', sendError); }
    }
  });

  ws.on('close', (code, reason) => {
    logger.info(`WebSocket closed for client ${clientId}: Code ${code}, Reason: ${reason || 'No reason provided'}`);
    const clientChannels = [];
    channels.forEach((clients, channelName) => { if (clients.has(ws)) clientChannels.push(channelName); });
    channels.forEach((clients, channelName) => {
      if (clients.delete(ws)) {
        try {
          clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify({ type: 'system', message: 'A client has left the channel', channel: channelName }));
              stats.messagesSent++;
            }
          });
        } catch (e) { logger.error(`Error notifying channel ${channelName} about client disconnect:`, e); stats.errors++; }
        if (clients.size === 0) { channels.delete(channelName); channelQueues.delete(channelName); }
      }
    });
    cleanupClient(ws, clientChannels);
    if (ws.data?.sessionId) {
      const currentHolder = sessionToClient.get(ws.data.sessionId);
      if (currentHolder === ws) sessionToClient.delete(ws.data.sessionId);
    }
    stats.activeConnections--;
  });
});

httpServer.listen(PORT, () => {
  logger.info(`Claude to Figma WebSocket server (Node relay) running on port ${PORT}`);
  logger.info(`Status endpoint available at http://localhost:${PORT}/status`);
});

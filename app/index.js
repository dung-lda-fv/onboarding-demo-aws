const http = require('http');
const { CloudWatchLogsClient, CreateLogGroupCommand, CreateLogStreamCommand, PutLogEventsCommand } = require('@aws-sdk/client-cloudwatch-logs');

const LOG_GROUP  = '/ecs/my-app';
const IMAGE_TAG  = process.env.IMAGE_TAG || 'local';
const LOG_STREAM = `app-${IMAGE_TAG}-${Date.now()}`;
const ENDPOINT   = process.env.LOCALSTACK_ENDPOINT || 'http://localhost:4566';
const PORT       = 3000;

const cw = new CloudWatchLogsClient({
  region: 'us-east-1',
  endpoint: ENDPOINT,
  credentials: { accessKeyId: 'test', secretAccessKey: 'test' },
});

// Tạo log group + stream khi khởi động (bỏ qua lỗi nếu đã tồn tại)
async function initLogs() {
  try { await cw.send(new CreateLogGroupCommand({ logGroupName: LOG_GROUP })); } catch (_) {}
  try { await cw.send(new CreateLogStreamCommand({ logGroupName: LOG_GROUP, logStreamName: LOG_STREAM })); } catch (_) {}
}

async function putLog(level, category, message, extra) {
  const entry = JSON.stringify({
    time:    new Date().toISOString(),
    level,
    version: IMAGE_TAG,
    stream:  LOG_STREAM,
    cat:     category,
    msg:     message,
    ...(extra || {}),
  });
  console.log(entry);
  try {
    await cw.send(new PutLogEventsCommand({
      logGroupName:  LOG_GROUP,
      logStreamName: LOG_STREAM,
      logEvents: [{ timestamp: Date.now(), message: entry }],
    }));
  } catch (e) {
    console.error('CW error:', e.message);
  }
}

let reqCount = 0;

const server = http.createServer(async (req, res) => {
  const start = Date.now();
  reqCount++;
  const reqId = `req-${reqCount}`;

  await putLog('INFO', 'HTTP', `${req.method} ${req.url} received`, { reqId });

  const body = JSON.stringify({ ok: true, version: IMAGE_TAG, reqId, path: req.url });
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(body + '\n');

  const durationMs = Date.now() - start;
  const level = durationMs > 200 ? 'WARN' : 'INFO';
  await putLog(level, 'HTTP', `${req.method} ${req.url} → 200 OK`, { reqId, durationMs });
});

initLogs().then(async () => {
  await putLog('INFO',  'STARTUP', `my-app starting`, { version: IMAGE_TAG, port: PORT });
  await putLog('INFO',  'STARTUP', `CloudWatch configured`, { endpoint: ENDPOINT, logGroup: LOG_GROUP, logStream: LOG_STREAM });
  server.listen(PORT, async () => {
    await putLog('INFO', 'STARTUP', `HTTP server ready, listening on :${PORT}`);
  });
});

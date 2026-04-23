const http = require('http');
const { CloudWatchLogsClient, CreateLogGroupCommand, CreateLogStreamCommand, PutLogEventsCommand } = require('@aws-sdk/client-cloudwatch-logs');

const LOG_GROUP  = '/ecs/my-app';
const LOG_STREAM = `app-${process.env.IMAGE_TAG || 'local'}-${Date.now()}`;
const ENDPOINT   = process.env.LOCALSTACK_ENDPOINT || 'http://localhost:4566';

const cw = new CloudWatchLogsClient({
  region: 'us-east-1',
  endpoint: ENDPOINT,
  credentials: { accessKeyId: 'test', secretAccessKey: 'test' },
});

// Tạo log group + stream khi khởi động (bỏ qua lỗi nếu đã tồn tại)
async function initLogs() {
  try { await cw.send(new CreateLogGroupCommand({ logGroupName: LOG_GROUP })); } catch (_) {}
  try { await cw.send(new CreateLogStreamCommand({ logGroupName: LOG_GROUP, logStreamName: LOG_STREAM })); } catch (_) {}
  console.log(`CloudWatch → ${ENDPOINT}  group=${LOG_GROUP}  stream=${LOG_STREAM}`);
}

async function putLog(message) {
  try {
    await cw.send(new PutLogEventsCommand({
      logGroupName:  LOG_GROUP,
      logStreamName: LOG_STREAM,
      logEvents: [{ timestamp: Date.now(), message }],
    }));
  } catch (e) {
    console.error('CW error:', e.message);
  }
}

const server = http.createServer(async (req, res) => {
  const msg = `${new Date().toISOString()} ${req.method} ${req.url} – v4 CloudWatch demo`;
  console.log(msg);
  await putLog(msg);
  res.writeHead(200);
  res.end('v4 – CloudWatch Logs demo!\n');
});

initLogs().then(() => {
  server.listen(3000, () => console.log('Running on port 3000'));
});

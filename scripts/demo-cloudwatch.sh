#!/bin/bash
# Demo đọc CloudWatch Logs từ LocalStack
# Chạy script này từ terminal VS Code (đã có Docker context đúng)

set -euo pipefail
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
EP="http://localhost:4566"
LOG_GROUP="/ecs/my-app"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " CloudWatch Logs Demo – LocalStack"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Start container (ghi log lên LocalStack CloudWatch)
echo ""
echo "[1/4] Starting app container..."
docker rm -f cw-demo 2>/dev/null || true
docker run -d --name cw-demo -p 3001:3000 \
  -e LOCALSTACK_ENDPOINT="http://host.docker.internal:4566" \
  -e IMAGE_TAG="demo-v4" \
  localhost:5000/my-app:latest
sleep 3

# ── 2. Generate traffic (tạo log events)
echo "[2/4] Generating 5 HTTP requests → app will write to CloudWatch..."
for i in 1 2 3 4 5; do
  curl -sf "http://localhost:3001/path-$i"
  echo ""
done
sleep 1

# ── 3. Đọc log từ LocalStack CloudWatch
echo ""
echo "[3/4] Reading CloudWatch Log Groups..."
aws --endpoint-url="$EP" logs describe-log-groups \
  --log-group-name-prefix "$LOG_GROUP" \
  --output table

echo ""
echo "[3/4] Reading Log Streams..."
STREAM=$(aws --endpoint-url="$EP" logs describe-log-streams \
  --log-group-name "$LOG_GROUP" \
  --order-by LastEventTime \
  --descending \
  --query 'logStreams[0].logStreamName' \
  --output text 2>/dev/null)
echo "Latest stream: $STREAM"

echo ""
echo "[4/4] Reading Log Events from stream '$STREAM'..."
aws --endpoint-url="$EP" logs get-log-events \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$STREAM" \
  --query 'events[*].message' \
  --output table 2>/dev/null || echo "No events yet (stream may be empty)"

echo ""
echo "✅ Demo complete!"
echo "   Try: curl http://localhost:3001 then re-run step 4 above"

# ── Cleanup (comment out nếu muốn giữ container chạy)
# docker rm -f cw-demo

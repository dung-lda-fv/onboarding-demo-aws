#!/bin/bash
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# Cấu hình
# ────────────────────────────────────────────────────────────────────────────
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="000000000000"
LOCALSTACK_ENDPOINT="http://localhost:4566"
# registry:2 container – thay thế ECR (LocalStack CE không lưu Docker image)
ECR_REGISTRY="localhost:5000"
ECR_REPO="my-app"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo latest)}"
FULL_IMAGE="${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=${AWS_REGION}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Deploy  →  ${FULL_IMAGE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Start LocalStack & Registry ─────────────────────────────────────────
echo "[1/5] Starting LocalStack & local registry..."
docker compose up -d localstack registry
echo "      Waiting for LocalStack to be healthy..."
until curl -sf "${LOCALSTACK_ENDPOINT}/_localstack/health" | grep -q '"ecr": "running"'; do
  sleep 3
done
echo "      LocalStack is ready."

# ── 2. Build Docker image ────────────────────────────────────────────────────
echo "[2/5] Building Docker image..."
docker build -t "${ECR_REPO}:${IMAGE_TAG}" ./app

# ── 3. Push vào local registry ──────────────────────────────────────────────
echo "[3/5] Pushing to local registry (localhost:5000)..."

# Không cần login – registry:2 không có auth
docker tag "${ECR_REPO}:${IMAGE_TAG}" "${FULL_IMAGE}"
docker push "${FULL_IMAGE}"
docker tag "${ECR_REPO}:${IMAGE_TAG}" "${ECR_REGISTRY}/${ECR_REPO}:latest"
docker push "${ECR_REGISTRY}/${ECR_REPO}:latest"

# Vẫn tạo ECR repo trên LocalStack (để ECS task definition hợp lệ)
aws --endpoint-url="${LOCALSTACK_ENDPOINT}" \
  ecr describe-repositories --repository-names "${ECR_REPO}" --region "${AWS_REGION}" \
  2>/dev/null || \
aws --endpoint-url="${LOCALSTACK_ENDPOINT}" \
  ecr create-repository --repository-name "${ECR_REPO}" --region "${AWS_REGION}"

# ── 4. Terraform apply ────────────────────────────────────────────────────────
echo "[4/5] Running Terraform..."
cd terraform
terraform init -upgrade -input=false
terraform apply -auto-approve \
  -var="image_tag=${IMAGE_TAG}" \
  -var="localstack_endpoint=${LOCALSTACK_ENDPOINT}"
cd ..

# ── 5. Force redeploy ECS service ─────────────────────────────────────────────
echo "[5/5] Redeploying ECS service..."
aws --endpoint-url="${LOCALSTACK_ENDPOINT}" ecs update-service \
  --cluster demo-cluster \
  --service my-app-service \
  --force-new-deployment \
  --region "${AWS_REGION}" > /dev/null

echo ""
echo "✅ Done! Image deployed: ${FULL_IMAGE}"

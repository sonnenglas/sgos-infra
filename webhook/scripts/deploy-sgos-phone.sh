#!/bin/sh
set -e

echo "=== Deploying sgos-phone to Hornbill ==="
echo "Repository: $1"
echo "Ref: $2"

ssh -i /root/.ssh/deploy_hornbill -o StrictHostKeyChecking=no stefan@100.67.57.25 << 'EOF'
set -e
echo "=== Pulling latest changes ==="
cd /srv/apps/sgos-phone/src
git pull --ff-only origin main

echo "=== Decrypting secrets ==="
cd /srv/apps/sgos-phone
sops --input-type dotenv --output-type dotenv -d src/.env.sops > .env

echo "=== Rebuilding and restarting ==="
docker compose down
docker compose up -d --build

echo "=== Waiting for health check ==="
sleep 10
curl -sf http://127.0.0.1:9000/health || echo "Health check failed"

echo "=== Deploy complete ==="
EOF

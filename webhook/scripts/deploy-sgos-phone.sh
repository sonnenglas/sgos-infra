#!/bin/sh
set -e

echo "=== Deploying sgos-phone to Hornbill ==="
echo "Repository: $1"
echo "Ref: $2"

ssh -i /root/.ssh/deploy_hornbill -o StrictHostKeyChecking=no stefan@100.67.57.25 << 'EOF'
set -e

APP_DIR=/srv/apps/sgos-phone
MAINTENANCE_FLAG="$APP_DIR/src/maintenance-mode/maintenance.flag"

echo "=== Entering maintenance mode ==="
touch "$MAINTENANCE_FLAG"

echo "=== Pulling latest changes ==="
cd "$APP_DIR/src"
git checkout -- .  # Discard any local changes
git pull --ff-only origin main

echo "=== Decrypting secrets ==="
cd "$APP_DIR"
sops --input-type dotenv --output-type dotenv -d src/.env.sops > .env

echo "=== Rebuilding app (proxy stays up for maintenance page) ==="
docker compose up -d --build phone db

echo "=== Waiting for app health check ==="
sleep 10
for i in 1 2 3 4 5; do
    if curl -sf http://127.0.0.1:8000/health > /dev/null 2>&1; then
        echo "App is healthy"
        break
    fi
    echo "Waiting for app... ($i/5)"
    sleep 5
done

echo "=== Ensuring proxy is running ==="
docker compose up -d proxy

echo "=== Exiting maintenance mode ==="
rm -f "$MAINTENANCE_FLAG"

echo "=== Final health check ==="
curl -sf http://127.0.0.1:9000/health || echo "Warning: Health check via proxy failed"

echo "=== Deploy complete ==="
EOF

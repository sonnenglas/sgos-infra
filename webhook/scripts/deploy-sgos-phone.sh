#!/bin/sh
# Deploy sgos-phone to Hornbill
# Triggered by GitHub webhook on push to main

set -e

echo "=== Deploying sgos-phone to Hornbill ==="
echo "Repository: $1"
echo "Ref: $2"

ssh -i /root/.ssh/deploy_hornbill -o StrictHostKeyChecking=no stefan@100.67.57.25 << 'EOF'
set -e

APP_DIR=/srv/apps/sgos-phone
PROXY_FLAG="/srv/proxy/hornbill/flags/phone.flag"

echo "=== Entering maintenance mode ==="
mkdir -p /srv/proxy/hornbill/flags
touch "$PROXY_FLAG"

echo "=== Pulling latest changes ==="
cd "$APP_DIR/src"
git checkout -- .  # Discard any local changes
git pull --ff-only origin main

echo "=== Validating app.json ==="
if [ -f "$APP_DIR/src/app.json" ]; then
    ERRORS=0
    for field in '.name' '.version' '.sgos.server' '.sgos.domain' '.scripts.backup' '.sgos.backup.output'; do
        val=$(jq -r "$field // empty" "$APP_DIR/src/app.json")
        if [ -z "$val" ]; then
            echo "ERROR: Missing required field: $field"
            ERRORS=$((ERRORS + 1))
        fi
    done
    if [ $ERRORS -gt 0 ]; then
        echo "FAILED: app.json validation failed with $ERRORS error(s)"
        rm -f "$PROXY_FLAG"  # Exit maintenance mode
        exit 1
    fi
    echo "app.json validation passed"
else
    echo "WARNING: app.json not found, skipping validation"
fi

echo "=== Decrypting secrets ==="
cd "$APP_DIR"
sops --input-type dotenv --output-type dotenv -d src/.env.sops > .env

echo "=== Rebuilding app ==="
docker compose up -d --build phone db

echo "=== Waiting for app health check ==="
sleep 10
HEALTHY=false
for i in 1 2 3 4 5 6; do
    if curl -sf http://127.0.0.1:8000/health > /dev/null 2>&1; then
        echo "App is healthy"
        HEALTHY=true
        break
    fi
    echo "Waiting for app... ($i/6)"
    sleep 5
done

if [ "$HEALTHY" = "false" ]; then
    echo "FAILED: App did not become healthy after 40 seconds"
    echo "Maintenance mode remains active - manual intervention required"
    echo "Check logs: docker logs sgos-phone-app"
    exit 1
fi

echo "=== Exiting maintenance mode ==="
rm -f "$PROXY_FLAG"

echo "=== Final health check ==="
if ! curl -sf http://127.0.0.1:9000/health > /dev/null 2>&1; then
    echo "WARNING: Health check via proxy failed, re-enabling maintenance mode"
    touch "$PROXY_FLAG"
    exit 1
fi

echo "=== Deploy complete ==="
EOF

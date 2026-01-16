#!/bin/sh
# Deploy sgos-docflow to Hornbill
# Triggered by GitHub webhook on push to main

set -e

echo "=== Deploying sgos-docflow to Hornbill ==="
echo "Repository: $1"
echo "Ref: $2"

ssh -i /root/.ssh/deploy_hornbill -o StrictHostKeyChecking=no stefan@100.67.57.25 << 'EOF'
set -e

APP_DIR=/srv/apps/sgos-docflow
PROXY_FLAG="/srv/proxy/hornbill/flags/docflow.flag"

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
docker compose up -d --build app db worker

echo "=== Waiting for Docker health status ==="
CONTAINER="sgos-docflow-app"
TIMEOUT=120
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || echo "starting")

    case "$STATUS" in
        healthy)
            echo "Container healthy (${ELAPSED}s)"
            break
            ;;
        unhealthy)
            echo "WARNING: Container health check failed (curl not in image)"
            echo "Checking app directly..."
            if curl -sf http://127.0.0.1:3001/health > /dev/null 2>&1; then
                echo "App responding - continuing despite Docker health status"
                STATUS="healthy"
                break
            fi
            echo "FAILED: App not responding"
            echo "Maintenance mode remains active - manual intervention required"
            echo "Check logs: docker logs $CONTAINER"
            exit 1
            ;;
        *)
            echo "Waiting... status=$STATUS (${ELAPSED}s/${TIMEOUT}s)"
            sleep 5
            ELAPSED=$((ELAPSED + 5))
            ;;
    esac
done

if [ "$STATUS" != "healthy" ]; then
    echo "Timeout - checking app directly..."
    if curl -sf http://127.0.0.1:3001/health > /dev/null 2>&1; then
        echo "App responding despite timeout"
    else
        echo "FAILED: Timeout after ${TIMEOUT}s and app not responding"
        echo "Maintenance mode remains active - manual intervention required"
        echo "Check logs: docker logs $CONTAINER"
        exit 1
    fi
fi

echo "=== Exiting maintenance mode ==="
rm -f "$PROXY_FLAG"

# Wait for nginx file cache to expire (2s cache + buffer)
sleep 3

echo "=== Final health check ==="
if ! curl -sf http://127.0.0.1:3001/health > /dev/null 2>&1; then
    echo "WARNING: Health check failed, re-enabling maintenance mode"
    touch "$PROXY_FLAG"
    exit 1
fi

echo "=== Deploy complete ==="
EOF

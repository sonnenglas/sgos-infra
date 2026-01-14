#!/bin/sh
# Deploy sgos-sangoma to Toucan (local)
# Triggered by GitHub webhook on push to main

set -e

echo "=== Deploying sgos-sangoma to Toucan ==="
echo "Repository: $1"
echo "Ref: $2"

SERVICE_DIR=/srv/services/sangoma
PROXY_FLAG="/srv/services/sgos-infra/proxy/toucan/flags/sangoma.flag"

echo "=== Entering maintenance mode ==="
mkdir -p /srv/services/sgos-infra/proxy/toucan/flags
touch "$PROXY_FLAG"

echo "=== Pulling latest changes ==="
cd "$SERVICE_DIR"
git checkout -- .  # Discard any local changes
git pull --ff-only origin main

echo "=== Rebuilding app ==="
docker compose up -d --build

echo "=== Waiting for Docker health status ==="
CONTAINER="sgos-sangoma-app"
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
            echo "FAILED: Container marked unhealthy by Docker"
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
    echo "FAILED: Timeout after ${TIMEOUT}s waiting for healthy status"
    echo "Maintenance mode remains active - manual intervention required"
    echo "Check logs: docker logs $CONTAINER"
    exit 1
fi

echo "=== Exiting maintenance mode ==="
rm -f "$PROXY_FLAG"

sleep 3

echo "=== Final health check ==="
if ! curl -sf http://127.0.0.1:8010/health > /dev/null 2>&1; then
    echo "WARNING: Health check failed, re-enabling maintenance mode"
    touch "$PROXY_FLAG"
    exit 1
fi

echo "=== Deploy complete ==="

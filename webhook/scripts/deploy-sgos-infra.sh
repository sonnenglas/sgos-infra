#!/bin/sh
# Deploy sgos-infra documentation
# Triggered by GitHub webhook on push to main
# Runs inside webhook container, uses docker to execute on host

set -e

REPO="$1"
REF="$2"
INFRA_DIR="/srv/services/sgos-infra"
COMPOSE_FILE="$INFRA_DIR/docker-compose.prod.yml"
PROXY_FLAG="/srv/proxy/toucan/flags/docs.flag"

echo "=== Deploy triggered ==="
echo "Repository: $REPO"
echo "Ref: $REF"
echo "Time: $(date)"

echo "=== Entering maintenance mode ==="
mkdir -p /srv/proxy/toucan/flags
touch "$PROXY_FLAG"

echo "=== Pulling latest changes ==="
docker run --rm \
  -v "$INFRA_DIR":/repo \
  -w /repo \
  --entrypoint sh \
  alpine/git -c "git config --global --add safe.directory /repo && git pull --ff-only origin main"

echo "=== Getting commit hash ==="
GIT_COMMIT=$(docker run --rm \
  -v "$INFRA_DIR":/repo \
  -w /repo \
  --entrypoint sh \
  alpine/git -c "git config --global --add safe.directory /repo && git rev-parse HEAD")
echo "Commit: $GIT_COMMIT"

echo "=== Rebuilding docs container ==="
GIT_COMMIT=$GIT_COMMIT docker compose -f "$COMPOSE_FILE" up -d --build docs

echo "=== Waiting for docs to be ready ==="
sleep 10

echo "=== Exiting maintenance mode ==="
rm -f "$PROXY_FLAG"

echo "=== Deploy complete ==="
echo "Deployed commit: $GIT_COMMIT"

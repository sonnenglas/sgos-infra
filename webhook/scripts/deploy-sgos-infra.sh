#!/bin/sh
# Deploy sgos-infra documentation
# Triggered by GitHub webhook on push to main
# Runs inside webhook container, uses docker to execute on host

set -e

REPO="$1"
REF="$2"
COMPOSE_FILE="/srv/services/sgos-infra/docker-compose.prod.yml"
MAINTENANCE_FLAG="/srv/services/sgos-infra/maintenance-mode/maintenance.flag"

echo "=== Deploy triggered ==="
echo "Repository: $REPO"
echo "Ref: $REF"
echo "Time: $(date)"

echo "=== Entering maintenance mode ==="
touch "$MAINTENANCE_FLAG"

echo "=== Pulling latest changes ==="
docker run --rm \
  -v /srv/services/sgos-infra:/repo \
  -w /repo \
  --entrypoint sh \
  alpine/git -c "git config --global --add safe.directory /repo && git pull --ff-only origin main"

echo "=== Getting commit hash ==="
GIT_COMMIT=$(docker run --rm \
  -v /srv/services/sgos-infra:/repo \
  -w /repo \
  --entrypoint sh \
  alpine/git -c "git config --global --add safe.directory /repo && git rev-parse HEAD")
echo "Commit: $GIT_COMMIT"

echo "=== Rebuilding docs container ==="
# Rebuild only docs - proxy stays up and serves maintenance page
GIT_COMMIT=$GIT_COMMIT docker compose -f "$COMPOSE_FILE" up -d --build docs

echo "=== Waiting for docs to be ready ==="
sleep 10

echo "=== Exiting maintenance mode ==="
rm -f "$MAINTENANCE_FLAG"

echo "=== Ensuring proxy is running ==="
GIT_COMMIT=$GIT_COMMIT docker compose -f "$COMPOSE_FILE" up -d proxy

echo "=== Deploy complete ==="
echo "Deployed commit: $GIT_COMMIT"

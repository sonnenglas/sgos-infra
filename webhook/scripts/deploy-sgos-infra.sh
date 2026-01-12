#!/bin/sh
# Deploy sgos-infra documentation
# Triggered by GitHub webhook on push to main
# Runs inside webhook container, uses docker to execute on host

set -e

REPO="$1"
REF="$2"

echo "=== Deploy triggered ==="
echo "Repository: $REPO"
echo "Ref: $REF"
echo "Time: $(date)"

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
  alpine/git -c "git rev-parse HEAD")
echo "Commit: $GIT_COMMIT"

echo "=== Restarting documentation service ==="
GIT_COMMIT=$GIT_COMMIT docker compose -f /srv/services/sgos-infra/docker-compose.prod.yml down
GIT_COMMIT=$GIT_COMMIT docker compose -f /srv/services/sgos-infra/docker-compose.prod.yml up -d

echo "=== Deploy complete ==="

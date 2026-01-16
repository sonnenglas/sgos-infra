#!/bin/sh
# Deploy sgos-infra to Toucan
# Triggered by GitHub webhook on push to main
# Runs inside webhook container, uses docker to execute on host
#
# Deploys:
#   - Documentation site (Docusaurus)
#   - Backup orchestrator and secrets
#   - Proxy configurations

set -e

REPO="$1"
REF="$2"
INFRA_DIR="/srv/services/sgos-infra"
COMPOSE_FILE="$INFRA_DIR/docker-compose.prod.yml"
PROXY_FLAG="/srv/proxy/toucan/flags/docs.flag"
BACKUPS_DIR="/srv/services/backups"

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

echo "=== Syncing backup orchestrator ==="
mkdir -p "$BACKUPS_DIR"
cp "$INFRA_DIR/toucan/backups/backup-orchestrator.sh" "$BACKUPS_DIR/"
chmod +x "$BACKUPS_DIR/backup-orchestrator.sh"

echo "=== Decrypting backup secrets ==="
docker run --rm \
  -v "$INFRA_DIR":/repo \
  -v "$BACKUPS_DIR":/output \
  -v /home/stefan/.config/sops/age:/root/.config/sops/age:ro \
  ghcr.io/getsops/sops:latest \
  -d --output-type dotenv --output /output/.env /repo/toucan/backups/.env.sops

echo "=== Syncing proxy configurations ==="
cp "$INFRA_DIR/proxy/toucan/nginx.conf" /srv/proxy/toucan/nginx.conf 2>/dev/null || true
cp "$INFRA_DIR/proxy/toucan/maintenance.html" /srv/proxy/toucan/maintenance.html 2>/dev/null || true

echo "=== Rebuilding docs container ==="
GIT_COMMIT=$GIT_COMMIT docker compose -f "$COMPOSE_FILE" up -d --build docs

echo "=== Waiting for docs to be ready ==="
sleep 10

echo "=== Exiting maintenance mode ==="
rm -f "$PROXY_FLAG"

echo "=== Deploy complete ==="
echo "Deployed commit: $GIT_COMMIT"
echo "Components deployed:"
echo "  - Documentation site"
echo "  - Backup orchestrator"
echo "  - Proxy configurations"

#!/bin/sh
# Deploy sgos-infra documentation
# Triggered by GitHub webhook on push to main

set -e

REPO="$1"
REF="$2"

echo "=== Deploy triggered ==="
echo "Repository: $REPO"
echo "Ref: $REF"
echo "Time: $(date)"

cd /srv/services/sgos-infra

echo "=== Pulling latest changes ==="
git pull origin main

echo "=== Restarting documentation service ==="
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

echo "=== Deploy complete ==="

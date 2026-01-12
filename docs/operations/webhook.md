---
title: Webhook Deployments
sidebar_position: 8
description: Automated deployment via GitHub webhooks
---

# Webhook Deployments

Automated deployment system triggered by GitHub push events. When code is pushed to `main`, the webhook triggers a deployment script.

## Architecture

```
GitHub                    Toucan                      Hornbill
┌──────────┐             ┌─────────────────┐         ┌──────────────┐
│ Push to  │────────────▶│ webhook:9000    │         │              │
│ main     │  POST       │                 │         │              │
│          │  HMAC-256   │ hooks.json      │         │              │
└──────────┘             │      │          │         │              │
                         │      ▼          │         │              │
                         │ deploy-*.sh ────┼── SSH ─▶│ git pull     │
                         │                 │         │ docker build │
                         └─────────────────┘         │ health check │
                                                     └──────────────┘
```

## Components

| File | Purpose |
|------|---------|
| `webhook/docker-compose.yml` | Webhook container configuration |
| `webhook/hooks.json` | Hook definitions and trigger rules |
| `webhook/scripts/deploy-*.sh` | Deployment scripts per app |

## Security Model

Every webhook request is validated:

1. **HMAC-SHA256 signature** - GitHub signs payloads with shared secret
2. **Branch filter** - Only `refs/heads/main` triggers deployment
3. **Repository filter** - Only specific `sonnenglas/*` repos accepted

The secret is stored in `WEBHOOK_SECRET` environment variable.

## Current Hooks

| Hook ID | Repository | Target | Script |
|---------|------------|--------|--------|
| `deploy-sgos-infra` | sonnenglas/sgos-infra | Toucan | `deploy-sgos-infra.sh` |
| `deploy-sgos-phone` | sonnenglas/sgos-phone | Hornbill | `deploy-sgos-phone.sh` |

## Adding a New SGOS App

### Step 1: Create the deploy script

Create `webhook/scripts/deploy-sgos-<app>.sh`:

```bash
#!/bin/sh
# Deploy sgos-<app> to Hornbill
set -e

echo "=== Deploying sgos-<app> to Hornbill ==="
echo "Repository: $1"
echo "Ref: $2"

ssh -i /root/.ssh/deploy_hornbill -o StrictHostKeyChecking=no stefan@100.67.57.25 << 'EOF'
set -e

APP_DIR=/srv/apps/sgos-<app>
PROXY_FLAG="/srv/proxy/hornbill/flags/<app>.flag"

echo "=== Entering maintenance mode ==="
mkdir -p /srv/proxy/hornbill/flags
touch "$PROXY_FLAG"

echo "=== Pulling latest changes ==="
cd "$APP_DIR/src"
git checkout -- .
git pull --ff-only origin main

echo "=== Validating app.json ==="
# ... validation logic ...

echo "=== Decrypting secrets ==="
cd "$APP_DIR"
sops --input-type dotenv --output-type dotenv -d src/.env.sops > .env

echo "=== Rebuilding app ==="
docker compose up -d --build

echo "=== Waiting for Docker health status ==="
CONTAINER="sgos-<app>-app"
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
            echo "FAILED: Container unhealthy"
            exit 1
            ;;
        *)
            sleep 5
            ELAPSED=$((ELAPSED + 5))
            ;;
    esac
done

echo "=== Exiting maintenance mode ==="
rm -f "$PROXY_FLAG"
sleep 3  # Wait for nginx cache

echo "=== Deploy complete ==="
EOF
```

### Step 2: Add hook to hooks.json

Add to `webhook/hooks.json`:

```json
{
  "id": "deploy-sgos-<app>",
  "execute-command": "/scripts/deploy-sgos-<app>.sh",
  "pass-arguments-to-command": [
    { "source": "payload", "name": "repository.full_name" },
    { "source": "payload", "name": "ref" }
  ],
  "trigger-rule": {
    "and": [
      {
        "match": {
          "type": "payload-hmac-sha256",
          "secret": "{{ getenv `WEBHOOK_SECRET` }}",
          "parameter": { "source": "header", "name": "X-Hub-Signature-256" }
        }
      },
      {
        "match": {
          "type": "value",
          "value": "refs/heads/main",
          "parameter": { "source": "payload", "name": "ref" }
        }
      },
      {
        "match": {
          "type": "value",
          "value": "sonnenglas/sgos-<app>",
          "parameter": { "source": "payload", "name": "repository.full_name" }
        }
      }
    ]
  }
}
```

### Step 3: Configure GitHub webhook

1. Go to GitHub repo → Settings → Webhooks → Add webhook
2. **Payload URL:** `https://webhook.sgl.as/hooks/deploy-sgos-<app>`
3. **Content type:** `application/json`
4. **Secret:** Same as `WEBHOOK_SECRET` on Toucan
5. **Events:** Just the push event
6. **Active:** ✓

### Step 4: Deploy webhook changes

```bash
# On Toucan
cd /srv/services/webhook
docker compose down
docker compose up -d
```

### Step 5: Add proxy flag file support

Ensure the Hornbill proxy config includes the new flag:

```nginx
# In /srv/proxy/hornbill/nginx.conf
location /<app>/ {
    set $maintenance 0;
    if (-f /flags/<app>.flag) { set $maintenance 1; }
    # ... rest of config
}
```

## Deployment Flow

1. Developer pushes to `main` branch
2. GitHub sends POST to `https://webhook.sgl.as/hooks/deploy-sgos-<app>`
3. Webhook validates HMAC signature, branch, and repo
4. Deploy script executes:
   - SSH to target server
   - Enable maintenance mode (flag file)
   - Pull latest code
   - Validate `app.json`
   - Decrypt secrets with SOPS
   - Rebuild and restart containers
   - Wait for Docker health check
   - Disable maintenance mode
5. App is live with new code

## Troubleshooting

### View webhook logs

```bash
ssh stefan@toucan
docker logs -f webhook
```

### Test webhook manually

```bash
# Trigger deployment without GitHub
curl -X POST https://webhook.sgl.as/hooks/deploy-sgos-phone \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=<calculated-hmac>" \
  -d '{"ref":"refs/heads/main","repository":{"full_name":"sonnenglas/sgos-phone"}}'
```

### Common issues

| Issue | Cause | Fix |
|-------|-------|-----|
| 401 Unauthorized | HMAC mismatch | Verify `WEBHOOK_SECRET` matches GitHub |
| No trigger | Branch filter | Only `main` triggers, not feature branches |
| SSH failure | Key missing | Check `/root/.ssh/deploy_hornbill` in container |
| Health timeout | App crash | Check `docker logs sgos-<app>-app` on Hornbill |

### Deployment stuck in maintenance

If deployment fails, maintenance mode stays active:

```bash
# On Hornbill
rm /srv/proxy/hornbill/flags/<app>.flag
```

## Webhook Container

The webhook runs [adnanh/webhook](https://github.com/adnanh/webhook) in a container:

```yaml
services:
  webhook:
    image: almir/webhook
    container_name: webhook
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - ./hooks.json:/etc/webhook/hooks.json
      - ./scripts:/scripts
      - /var/run/docker.sock:/var/run/docker.sock
      - ~/.ssh:/root/.ssh:ro
    environment:
      - WEBHOOK_SECRET=${WEBHOOK_SECRET}
```

## Location

```
/srv/services/webhook/
├── docker-compose.yml
├── hooks.json
└── scripts/
    ├── deploy-sgos-infra.sh
    └── deploy-sgos-phone.sh
```

---
title: Deployment
sidebar_position: 2
description: How apps are deployed, webhook automation, and maintenance mode
---

# Deployment

Apps are deployed as Docker Compose stacks with automated GitHub webhooks.

## Overview

| Aspect | Approach |
|--------|----------|
| Deployment model | Source-based (code on server via git) |
| Container orchestration | Docker Compose |
| External access | Cloudflare Tunnel |
| Automation | GitHub webhooks trigger deploy scripts |
| Configuration | app.json + docker-compose.yml |
| Secrets | SOPS-encrypted .env.sops files |

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | **Production** - auto-deploys on push |
| feature branches | Development work, no auto-deploy |

Push to `main` triggers automatic deployment via GitHub webhook.

---

## Webhook Automation

### Architecture

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

### Security Model

Every webhook request is validated:

1. **HMAC-SHA256 signature** - GitHub signs payloads with shared secret
2. **Branch filter** - Only `refs/heads/main` triggers deployment
3. **Repository filter** - Only specific `sonnenglas/*` repos accepted

### Current Hooks

| Hook ID | Repository | Target | Script |
|---------|------------|--------|--------|
| `deploy-sgos-infra` | sonnenglas/sgos-infra | Toucan | `deploy-sgos-infra.sh` |
| `deploy-sgos-phone` | sonnenglas/sgos-phone | Hornbill | `deploy-sgos-phone.sh` |
| `deploy-sgos-docflow` | sonnenglas/sgos-docflow | Hornbill | `deploy-sgos-docflow.sh` |
| `deploy-sgos-sangoma` | sonnenglas/sgos-sangoma | Toucan | `deploy-sgos-sangoma.sh` |

---

## SSH Deploy Keys

Hornbill needs SSH access to GitHub to pull app repos during deployment. Keys are managed as code in this repo and deployed automatically.

### How It Works

```
infra repo                    Toucan                      Hornbill
┌──────────────────┐         ┌──────────────┐            ┌────────────────┐
│ hornbill/ssh/    │         │              │            │ ~/.ssh/        │
│ ├── config       │──push──▶│ infra deploy │───SSH────▶│ ├── config     │
│ ├── github_*.sops│         │ (decrypts)   │   copy    │ ├── github_*   │
└──────────────────┘         └──────────────┘            └────────────────┘
```

### Files (in this repo)

| File | Purpose |
|------|---------|
| `hornbill/ssh/config` | SSH host aliases for each repo |
| `hornbill/ssh/github_deploy.sops` | Encrypted deploy key for docflow |
| `hornbill/ssh/github_phone.sops` | Encrypted deploy key for phone |

### Why Per-Repo Keys?

GitHub doesn't allow the same deploy key on multiple repos. Each repo needs its own key with a corresponding SSH host alias:

```
# In SSH config
Host github-docflow          # Used in git remote URL
    HostName github.com
    IdentityFile ~/.ssh/github_deploy

# Git remote uses alias
origin  git@github-docflow:sonnenglas/sgos-docflow.git
```

### Adding a Key for a New App

1. Generate key on Hornbill:
   ```bash
   ssh-keygen -t ed25519 -C "hornbill-newapp" -f ~/.ssh/github_newapp -N ''
   ```

2. Add as deploy key on GitHub repo (read-only)

3. Copy private key to this repo and encrypt:
   ```bash
   scp hornbill:~/.ssh/github_newapp /tmp/
   cp /tmp/github_newapp hornbill/ssh/github_newapp.sops
   sops -e -i hornbill/ssh/github_newapp.sops
   rm /tmp/github_newapp
   ```

4. Add host alias to `hornbill/ssh/config`

5. Update git remote on Hornbill:
   ```bash
   cd /srv/apps/sgos-newapp/src
   git remote set-url origin git@github-newapp:sonnenglas/sgos-newapp.git
   ```

6. Push to main - keys deploy automatically

---

## Maintenance Mode

During deployments, apps display a maintenance page instead of 502 errors.

### How It Works

A **single nginx reverse proxy per server** sits between Cloudflare Tunnel and all apps:

```
Cloudflare Tunnel → sgos-proxy (nginx) → App
                         ↓
                   checks flag file
                   exists? → maintenance.html
                   no? → forward to app
```

Apps don't need any maintenance-mode code.

### Deployment Flow

1. Deploy script touches flag file
2. nginx serves maintenance page
3. App rebuilds (users see maintenance page)
4. Docker health check passes
5. Deploy script removes flag
6. nginx resumes proxying

### Manual Maintenance

```bash
# Enter maintenance (single app)
touch /srv/proxy/hornbill/flags/phone.flag

# Exit maintenance
rm /srv/proxy/hornbill/flags/phone.flag

# Global maintenance (all apps)
touch /srv/proxy/hornbill/flags/global.flag
```

---

## Adding a New SGOS App

### Step 1: Create deploy script

Create `webhook/scripts/deploy-sgos-<app>.sh`:

```bash
#!/bin/sh
set -e

echo "=== Deploying sgos-<app> to Hornbill ==="

ssh -i /root/.ssh/deploy_hornbill stefan@100.67.57.25 << 'EOF'
set -e

APP_DIR=/srv/apps/sgos-<app>
PROXY_FLAG="/srv/proxy/hornbill/flags/<app>.flag"

echo "=== Entering maintenance mode ==="
touch "$PROXY_FLAG"

echo "=== Pulling latest changes ==="
cd "$APP_DIR/src"
git checkout -- .
git pull --ff-only origin main

echo "=== Decrypting secrets ==="
cd "$APP_DIR"
sops --input-type dotenv --output-type dotenv -d src/.env.sops > .env

echo "=== Rebuilding app ==="
docker compose up -d --build

echo "=== Waiting for health check ==="
CONTAINER="sgos-<app>-app"
TIMEOUT=120
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || echo "starting")
    case "$STATUS" in
        healthy) echo "Container healthy"; break ;;
        unhealthy) echo "FAILED: Container unhealthy"; exit 1 ;;
        *) sleep 5; ELAPSED=$((ELAPSED + 5)) ;;
    esac
done

echo "=== Exiting maintenance mode ==="
rm -f "$PROXY_FLAG"
sleep 3  # Wait for nginx cache

echo "=== Deploy complete ==="
EOF
```

### Step 2: Add hook to hooks.json

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

### Step 4: Add proxy config

Add server block to `/srv/proxy/hornbill/nginx.conf`:

```nginx
server {
    listen <PORT>;
    resolver 127.0.0.11 valid=10s;
    set $upstream sgos-<app>:<internal-port>;

    error_page 503 @maintenance;
    location @maintenance {
        root /srv;
        try_files /maintenance.html =503;
    }

    location / {
        if (-f /srv/flags/global.flag) { return 503; }
        if (-f /srv/flags/<app>.flag) { return 503; }
        proxy_pass http://$upstream;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Step 5: Deploy changes

```bash
# Restart webhook on Toucan
cd /srv/services/webhook && docker compose down && docker compose up -d

# Reload proxy on Hornbill
docker exec sgos-proxy nginx -s reload
```

---

## Manual Deployment

```bash
ssh stefan@hornbill
cd /srv/apps/sgos-<app>

# Enter maintenance
touch /srv/proxy/hornbill/flags/<app>.flag

# Pull and rebuild
cd src && git pull && cd ..
sops -d src/.env.sops > .env
docker compose up -d --build

# Wait for health, then exit maintenance
rm /srv/proxy/hornbill/flags/<app>.flag
```

## Rollback

```bash
cd /srv/apps/sgos-<app>/src
git log --oneline  # Find previous commit
git checkout <commit>
cd .. && docker compose up -d --build
```

**Note:** Check `app.json` migration field first. If `breaking`, restore database from backup before rollback.

---

## Troubleshooting

### View webhook logs

```bash
ssh stefan@toucan
docker logs -f webhook
```

### Deployment stuck in maintenance

```bash
# On Hornbill
rm /srv/proxy/hornbill/flags/<app>.flag
```

### 502 Bad Gateway after restart

nginx caches DNS for 10 seconds. Wait or reload:

```bash
docker exec sgos-proxy nginx -s reload
```

### App not reachable through proxy

Verify app is on the `sgos` network:

```bash
docker inspect <container> --format '{{json .NetworkSettings.Networks}}' | jq 'keys'
docker network connect sgos <container>  # if missing
```

## Files

### Infrastructure Repo (source of truth)

| Path | Purpose |
|------|---------|
| `webhook/hooks.json` | Hook definitions |
| `webhook/scripts/` | Deploy scripts |
| `hornbill/ssh/` | SSH deploy keys (encrypted) |
| `proxy/*/nginx.conf` | Proxy configuration |

### On Servers (deployed)

| Path | Server | Purpose |
|------|--------|---------|
| `/srv/services/sgos-infra/` | Toucan | Cloned infra repo |
| `/srv/proxy/*/nginx.conf` | Both | Proxy configuration |
| `/srv/proxy/*/flags/` | Both | Maintenance flag files |
| `/home/stefan/.ssh/github_*` | Hornbill | Decrypted deploy keys |

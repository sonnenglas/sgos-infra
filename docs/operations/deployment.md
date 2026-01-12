---
title: Deployment
sidebar_position: 1
description: How apps are deployed
---

# Deployment

Apps are deployed as Docker Compose stacks with Cloudflare Tunnel for external access.

## Conventions

| Aspect | Approach |
|--------|----------|
| Deployment model | Source-based (code on server via git) |
| Container orchestration | Docker Compose |
| External access | Cloudflare Tunnel |
| Reverse proxy | Optional (Traefik) - currently using direct tunnel routing |
| Configuration | app.json + docker-compose.yml |
| Secrets | SOPS-encrypted .env.sops files (see [Secrets Management](./secrets)) |

## Directory Structure

### Hornbill (App Server)

```
/srv/
├── apps/
│   └── sgos-<name>/
│       ├── app.json          # App metadata
│       ├── docker-compose.yml
│       ├── .env              # Secrets
│       ├── src/              # Source code (git clone)
│       ├── data/             # Persistent data
│       └── backup/           # Backup output
└── services/
    └── monitoring/           # Dozzle agent, Beszel agent
```

### Toucan (Control Server)

```
/srv/
└── services/
    ├── monitoring/           # Beszel, Dozzle, Homepage, Watchtower, PocketID
    ├── glitchtip/            # Error tracking
    └── sgos-infra/           # This documentation
```

## Workflow

### Manual Deployment

**Deploy:** SSH to server, git pull, docker compose up -d --build

**Rollback:** git checkout to previous tag, rebuild. Check `app.json` migration field first—if `breaking`, restore database before rollback.

### Auto-Deployment (sgos-infra)

The documentation site deploys automatically when pushing to `main`:

```
Push to main → GitHub webhook → webhook.sgl.as → Toucan pulls & restarts
```

**How it works:**

1. GitHub sends POST to `https://webhook.sgl.as/hooks/deploy-sgos-infra`
2. [adnanh/webhook](https://github.com/adnanh/webhook) verifies HMAC signature
3. Triggers `deploy-sgos-infra.sh` which:
   - Runs `git pull` via alpine/git container
   - Restarts the Docusaurus container

**Configuration:**

| File | Purpose |
|------|---------|
| `webhook/docker-compose.yml` | Webhook service |
| `webhook/hooks.json` | Trigger rules (repo, branch, signature) |
| `webhook/scripts/deploy-sgos-infra.sh` | Deployment script |
| `/srv/services/webhook/.env` | Secret (not in git) |

**Security:**

- HMAC-SHA256 signature verification
- Only triggers on `main` branch
- Only triggers for `sonnenglas/sgos-infra` repo

## Routing

### Current Setup (Direct Tunnel)

Services bind to localhost ports and Cloudflare Tunnel routes directly to them:

```
Internet → Cloudflare Tunnel → localhost:<port> → Container
```

### Optional: Traefik

For more complex routing needs (multiple containers per domain, load balancing), Traefik can be added:

```
Internet → Cloudflare Tunnel → Traefik → Container
```

Apps would join a shared Docker network and use Traefik labels for routing.

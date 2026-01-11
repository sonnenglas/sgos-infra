---
title: Deployment
sidebar_position: 1
description: How apps are deployed
---

# Deployment

Apps are deployed as Docker Compose stacks with Traefik for routing.

## Conventions

| Aspect | Approach |
|--------|----------|
| Deployment model | Source-based (code on server via git) |
| Container orchestration | Docker Compose |
| Reverse proxy | Traefik |
| Configuration | app.json + docker-compose.yml |
| Secrets | .env files (not in git) |

## Directory Structure

### Hornbill (App Server)

```
/srv/
├── infra/                    # Traefik, Cloudflare Tunnel
└── apps/
    └── sgos-<name>/
        ├── app.json          # App metadata
        ├── docker-compose.yml
        ├── .env              # Secrets
        ├── src/              # Source code (git clone)
        ├── data/             # Persistent data
        └── backup/           # Backup output
```

### Toucan (Control Server)

```
/srv/
├── monitoring/               # Grafana/Loki/Alloy
├── services/                 # GlitchTip, etc.
├── scripts/                  # Backup orchestration
└── backups/                  # Collected backups
```

## Workflow

**Deploy:** SSH to server, git pull, docker compose up -d --build

**Rollback:** git checkout to previous tag, rebuild. Check `app.json` migration field first—if `breaking`, restore database before rollback.

## Routing

Apps join the shared `sgos` Docker network and use Traefik labels for routing. Traefik runs at `/srv/infra/traefik/`.

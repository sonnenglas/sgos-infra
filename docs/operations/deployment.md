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
| Secrets | .env files (not in git) |

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

**Deploy:** SSH to server, git pull, docker compose up -d --build

**Rollback:** git checkout to previous tag, rebuild. Check `app.json` migration field first—if `breaking`, restore database before rollback.

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

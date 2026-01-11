# Sonnenglas Infrastructure

Infrastructure configuration and documentation for Sonnenglas self-hosted systems.

## Overview

Two-server setup on Netcup, connected via Tailscale mesh network, with external access through Cloudflare Tunnel.

| Server | Role | Services |
|--------|------|----------|
| **Toucan** | Control | Monitoring (Grafana/Loki), GlitchTip, Backup orchestration |
| **Hornbill** | Applications | SGOS business apps (Xhosa, Inventory, etc.) |

## Quick Access

| Service | URL |
|---------|-----|
| Grafana | http://toucan:3001 (Tailscale) |
| GlitchTip | https://glitchtip.sgl.as |

## Documentation

See [`docs/`](./docs/README.md) for detailed documentation:

- [Architecture](./docs/architecture.md) - Network topology and data flows
- [API Strategy](./docs/api-strategy.md) - API versioning and contracts
- [App Schema](./docs/app-schema.md) - Standard app.json configuration
- [Deployment](./docs/services/deployment.md) - How apps are deployed
- [Backups](./docs/backups.md) - Backup strategy and restore procedures
- [Servers](./docs/servers/) - Toucan and Hornbill setup
- [Services](./docs/services/) - Monitoring, GlitchTip

## Repository Structure

```
├── docs/                 # Documentation
├── templates/            # App templates
│   └── app.json          # Standard app.json template
├── toucan/               # Toucan server configs
│   ├── monitoring/       # Grafana/Loki/Alloy stack
│   └── scripts/          # Backup orchestration
├── hornbill/             # Hornbill server configs
└── Sonnenglas.md         # SGOS architecture and concept
```

## Tech Stack

- **Servers:** Netcup VPS (Ubuntu 24.04)
- **Networking:** Tailscale, Cloudflare Tunnel
- **Deployments:** Docker Compose + Traefik (source-based)
- **App Config:** app.json (Heroku-compatible with SGOS extensions)
- **Monitoring:** Grafana + Loki + Alloy
- **Error Tracking:** GlitchTip
- **Backups:** Toucan (local) → Cloudflare R2 (offsite) via Restic

## Browse Documentation Locally

Run the documentation site with Docker:

```bash
docker compose -f docker-compose.docs.yml up
```

Then open http://localhost:4200 in your browser.

# Sonnenglas Infrastructure

Infrastructure configuration and documentation for Sonnenglas self-hosted systems.

## Overview

Two-server setup on Netcup, connected via Tailscale mesh network, with external access through Cloudflare Tunnel.

| Server | Role | Services |
|--------|------|----------|
| **Toucan** | Control | Dokploy, Grafana/Loki, GlitchTip |
| **Hornbill** | Applications | Business apps (Xhosa, Beanstock, etc.) |

## Quick Access

| Service | URL |
|---------|-----|
| Dokploy | https://dokploy-toucan.sgl.as |
| Grafana | http://toucan:3001 (Tailscale) |
| GlitchTip | https://glitchtip.sgl.as |

## Documentation

See [`docs/`](./docs/README.md) for detailed documentation:

- [Architecture](./docs/architecture.md) - Network topology and data flows
- [Backups](./docs/backups.md) - Backup strategy and restore procedures
- [Servers](./docs/servers/) - Toucan and Hornbill setup
- [Services](./docs/services/) - Dokploy, Monitoring, GlitchTip

## Repository Structure

```
├── docs/                 # Documentation
├── toucan/               # Toucan server configs
│   ├── monitoring/       # Grafana/Loki/Alloy stack
│   └── glitchtip-compose.yml
├── hornbill/             # Hornbill server configs
└── Sonnenglas.md         # Original architecture plan
```

## Tech Stack

- **Servers:** Netcup VPS (Ubuntu 24.04)
- **Networking:** Tailscale, Cloudflare Tunnel
- **Deployments:** Dokploy (Docker Swarm)
- **Monitoring:** Grafana + Loki + Alloy
- **Error Tracking:** GlitchTip
- **Backups:** Cloudflare R2

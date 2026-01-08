# Sonnenglas Infrastructure Documentation

Documentation for the Sonnenglas self-hosted infrastructure.

## Quick Links

- [Architecture Overview](./architecture.md)
- [Backup Strategy](./backups.md)

### Servers

- [Toucan](./servers/toucan.md) - Control server (Dokploy, Monitoring, GlitchTip)
- [Hornbill](./servers/hornbill.md) - Application server

### Services

- [Dokploy](./services/dokploy.md) - Deployment platform
- [Monitoring](./services/monitoring.md) - Grafana, Loki, Alloy
- [GlitchTip](./services/glitchtip.md) - Error tracking

## Access

| Service | URL | Access |
|---------|-----|--------|
| Dokploy | https://dokploy-toucan.sgl.as | Cloudflare Tunnel |
| Grafana | http://toucan:3001 | Tailscale only |
| GlitchTip | https://glitchtip.sgl.as | Cloudflare Tunnel |

## Server Overview

| Server | Role | IP | Tailscale |
|--------|------|-----|-----------|
| Toucan | Control | 152.53.160.251 | 100.102.199.98 |
| Hornbill | Apps | 159.195.68.119 | 100.67.57.25 |

## Tech Stack

- **Hosting:** Netcup VPS (Vienna datacenter)
- **VPN:** Tailscale mesh network
- **External Access:** Cloudflare Tunnel
- **Deployments:** Dokploy (Docker Swarm)
- **Monitoring:** Grafana + Loki + Alloy
- **Error Tracking:** GlitchTip
- **Backups:** Cloudflare R2

---
title: Architecture
sidebar_position: 1
description: Network topology and server setup
---

# Architecture

## Servers

Both servers are hosted by Netcup in Nuremberg, Germany.

| Property | Toucan (Control) | Hornbill (Apps) |
|----------|------------------|-----------------|
| Public IP | 152.53.160.251 | 159.195.68.119 |
| Tailscale IP | 100.102.199.98 | 100.67.57.25 |
| CPU | 8 vCPU | 12 vCPU |
| RAM | 16 GB | 32 GB |
| Disk | 1 TB NVMe | 1 TB NVMe |

**Access:** SSH via Tailscale only (`ssh stefan@toucan` / `ssh stefan@hornbill`)

### Toucan (Control)

Orchestration, monitoring, and shared services:
- Grafana + Loki (log aggregation)
- GlitchTip (error tracking)
- PocketID (identity provider)
- SGOS Status page
- Webhook deployment receiver
- Backup orchestration
- Watchtower (auto-updates)

### Hornbill (Apps)

SGOS business applications:
- All `sgos-*` applications
- Alloy (log shipping to Toucan)
- Cloudflare Tunnel

## Network Topology

```
                    ┌─────────────────┐
                    │   Cloudflare    │
                    │   Zero Trust    │
                    └────────┬────────┘
                             │ Tunnels
                             ▼
        ┌─────────────────────────────────────┐
        │     *.sgl.as (public services)      │
        └─────────────────────────────────────┘
                             │
        ┌────────────────────┴────────────────┐
        ▼                                     ▼
┌─────────────────┐                   ┌─────────────────┐
│     TOUCAN      │◄─────────────────►│    HORNBILL     │
│  (Control)      │    Tailscale      │  (Apps)         │
└─────────────────┘                   └─────────────────┘
```

## Security

- **Public access:** Cloudflare Tunnel only (no direct public access)
- **Internal:** Tailscale mesh network
- **SSH:** Tailscale only (public SSH disabled)
- **Firewall:** UFW denies all except tailscale0 and port 443

## Database Strategy

Every app gets its own Postgres instance for isolation and portability.

Cross-app analytics (when needed): read-only analytics database synced nightly from app databases.

## Directory Structure

### Hornbill (App Server)

```
/srv/
├── apps/
│   └── sgos-<name>/
│       ├── app.json          # App metadata
│       ├── docker-compose.yml
│       ├── .env              # Secrets (decrypted)
│       ├── src/              # Source code (git clone)
│       ├── data/             # Persistent data
│       └── backup/           # Backup output
├── proxy/                    # Maintenance mode proxy
│   └── hornbill/
│       ├── nginx.conf
│       ├── maintenance.html
│       └── flags/
└── services/
    └── alloy/                # Log shipping
```

### Toucan (Control Server)

```
/srv/
├── config/
│   └── monitoring/           # Grafana, Loki, Alloy
├── services/
│   ├── status/               # Status page
│   ├── webhook/              # GitHub webhook receiver
│   ├── backups/              # Backup orchestrator
│   ├── glitchtip/            # Error tracking
│   └── sgos-infra/           # This documentation
├── backups/
│   ├── staging/              # Collected backups
│   └── status.json
└── proxy/
    └── toucan/               # Maintenance mode proxy
```

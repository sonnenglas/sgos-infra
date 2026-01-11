---
title: Architecture Overview
sidebar_position: 1
description: Network topology and server setup
---

# Architecture Overview

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

- Grafana/Loki/Alloy (centralized logging)
- GlitchTip (error tracking)
- Backup orchestration

### Hornbill (Apps)

- SGOS applications
- Traefik (reverse proxy)
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

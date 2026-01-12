---
title: Monitoring
sidebar_position: 1
description: Server metrics, Docker logs, and log analytics
---

# Monitoring

Server monitoring with Beszel, real-time Docker logs with Dozzle, and log analytics with Grafana/Loki.

## Services

| Service | URL | Purpose |
|---------|-----|---------|
| Dashboard | https://dashboard.sgl.as | Homepage with links to all services |
| Beszel | https://beszel.sgl.as | Server metrics (CPU, memory, disk, network) |
| Dozzle | https://dozzle.sgl.as | Real-time Docker container logs |
| Grafana | https://grafana.sgl.as | Log analytics and querying |

## Architecture

### Grafana / Loki / Alloy

Centralized log aggregation from all Docker containers on both servers.

```
Hornbill                        Toucan
┌──────────────┐                ┌──────────────┐
│ Docker       │                │ Docker       │
│ containers   │                │ containers   │
│     │        │                │     │        │
│     ▼        │                │     ▼        │
│   Alloy      │────────────────│   Alloy      │
│ server=      │   port 3100    │ server=      │
│ hornbill     │                │ toucan       │
└──────────────┘                │     │        │
                                │     ▼        │
                                │   Loki       │
                                │     │        │
                                │     ▼        │
                                │  Grafana ────┼──▶ grafana.sgl.as
                                └──────────────┘
```

- **Alloy** discovers and collects logs from all Docker containers
- **Loki** stores logs with 30-day retention
- **Grafana** provides the query UI

Logs are labeled with `server=toucan` or `server=hornbill` for filtering.

**Example queries:**
```logql
{server="hornbill"}                    # All Hornbill logs
{container="phone"}                    # Phone app logs
{server="toucan"} |= "error"           # Toucan errors
```

### Beszel

- **Hub** runs on Toucan (port 8090)
- **Agents** run on both Toucan and Hornbill (port 45876)
- Agents send metrics to hub via Tailscale

### Dozzle

- **Central instance** runs on Toucan (port 8888)
- **Remote agent** runs on Hornbill (port 7007)
- Shows logs from both servers in a single UI

## Location

| Service | Server | Path |
|---------|--------|------|
| Grafana, Loki, Alloy | Toucan | `/srv/config/monitoring/` |
| Beszel, Dozzle, Homepage | Toucan | `/srv/services/monitoring/` |
| Alloy (remote) | Hornbill | `/srv/services/alloy/` |

## Authentication

**Grafana:** Protected by Cloudflare Access. After Google SSO, use Grafana's built-in login (admin/admin, change on first use).

**Beszel and Dozzle:** Support auto-login via Cloudflare Zero Trust headers:

- User authenticates with Google via Cloudflare Zero Trust
- Cloudflare passes `Cf-Access-Authenticated-User-Email` header
- Apps read header and auto-login the user

### Configuration

**Beszel:**
```yaml
environment:
  - TRUSTED_AUTH_HEADER=Cf-Access-Authenticated-User-Email
```

**Dozzle:**
```yaml
environment:
  - DOZZLE_AUTH_PROVIDER=forward-proxy
  - DOZZLE_AUTH_HEADER_USER=Cf-Access-Authenticated-User-Email
  - DOZZLE_AUTH_HEADER_EMAIL=Cf-Access-Authenticated-User-Email
  - DOZZLE_AUTH_HEADER_NAME=Cf-Access-Authenticated-User-Email
```

## Auto-Updates

Watchtower automatically updates monitoring containers daily at 4 AM.

Containers must have the label `com.centurylinklabs.watchtower.enable=true` to be updated.

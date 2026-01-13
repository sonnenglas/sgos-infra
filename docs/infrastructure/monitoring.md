---
title: Monitoring
sidebar_position: 3
description: Logs, metrics, error tracking, and status page
---

# Monitoring

Centralized monitoring with Grafana/Loki for logs, GlitchTip for errors, and a status page for health visibility.

## Services Overview

| Service | URL | Purpose |
|---------|-----|---------|
| SGOS Status | [sgos-status.sgl.as](https://sgos-status.sgl.as) | Real-time app health dashboard |
| Grafana | [grafana.sgl.as](https://grafana.sgl.as) | Log analytics and querying |
| GlitchTip | [glitchtip.sgl.as](https://glitchtip.sgl.as) | Error tracking (Sentry-compatible) |

---

## Log Aggregation (Grafana / Loki / Alloy)

Centralized log aggregation from all Docker containers on both servers.

### Architecture

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

### Example Queries

```logql
{server="hornbill"}                    # All Hornbill logs
{container="phone"}                    # Phone app logs
{server="toucan"} |= "error"           # Toucan errors
{container=~"glitchtip.*"} |= "error"  # GlitchTip errors
```

### Authentication

Protected by Cloudflare Access (Google SSO). After SSO, use Grafana's built-in login.

---

## Error Tracking (GlitchTip)

Self-hosted error tracking, compatible with Sentry SDKs.

### Access

- **URL:** [glitchtip.sgl.as](https://glitchtip.sgl.as)
- **Internal:** `http://toucan:8000`

### Integration

Apps use the standard Sentry SDK, configured with a GlitchTip DSN. Create a project in the GlitchTip web UI to get the DSN.

```python
# Example Python integration
import sentry_sdk

sentry_sdk.init(
    dsn="https://...@glitchtip.sgl.as/1",
    traces_sample_rate=0.1,
)
```

---

## Status Page

Real-time status page showing health, version, and deployment info for all SGOS applications.

### Access

| Property | Value |
|----------|-------|
| URL | [sgos-status.sgl.as](https://sgos-status.sgl.as) |
| Auth | Cloudflare Access (Google SSO) |
| Server | Toucan |
| Port | 3004 |

### Features

- Real-time health status with visual indicators
- App version display
- Last deployment time (relative)
- Direct links to GitHub commits
- Scheduled jobs viewer (shows all cron jobs across servers)
- Auto-refresh every 60 seconds
- "All Systems Operational" summary banner

### Architecture

```
Toucan (/srv/services/status/)
┌─────────────────────────────────────────────────┐
│                                                 │
│   status.py ──SSH──▶ Hornbill                  │
│       │              - docker inspect           │
│       │              - git log                  │
│       │              - app.json                 │
│       ▼                                         │
│   apps.json                                     │
│       │                                         │
│       ▼                                         │
│   nginx:80 ──▶ index.html + apps.json          │
│       │                                         │
└───────┼─────────────────────────────────────────┘
        │
        ▼
   Cloudflare Tunnel ──▶ sgos-status.sgl.as
```

### Status States

| State | Indicator | Meaning |
|-------|-----------|---------|
| `healthy` | Green pulse | Docker reports container healthy |
| `unhealthy` | Red pulse | Docker reports container unhealthy |
| `starting` | Yellow pulse | Container starting, health check pending |
| `not-running` | Gray | Container not found or stopped |

### Scheduled Jobs

The status page also displays all cron jobs running across servers:

| Server | Schedule | Command |
|--------|----------|---------|
| Toucan | Daily 03:00 | backup-orchestrator.sh |
| Toucan | Every minute | status.py |

---

## Location

| Service | Server | Path |
|---------|--------|------|
| Grafana, Loki, Alloy | Toucan | `/srv/config/monitoring/` |
| GlitchTip | Toucan | `/srv/services/glitchtip/` |
| Status Page | Toucan | `/srv/services/status/` |
| Alloy (remote) | Hornbill | `/srv/services/alloy/` |

---

## Auto-Login with Cloudflare Headers

Services support auto-login via Cloudflare Zero Trust headers:

1. User authenticates with Google via Cloudflare Zero Trust
2. Cloudflare passes `Cf-Access-Authenticated-User-Email` header
3. Apps read header and auto-login the user

### Configuration Examples

**GlitchTip:** Uses Django's `REMOTE_USER` authentication

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
```

---

## Auto-Updates

Watchtower automatically updates monitoring containers daily at 4 AM.

Containers must have the label `com.centurylinklabs.watchtower.enable=true` to be updated.

---

## Management Commands

### Grafana/Loki Stack

```bash
ssh stefan@toucan
cd /srv/config/monitoring
docker compose up -d
docker compose logs -f
docker compose restart
```

### Status Page

```bash
cd /srv/services/status
docker compose ps
docker compose restart
python3 status.py  # Run collector manually
cat apps.json | jq .
```

### GlitchTip

```bash
cd /srv/services/glitchtip
docker compose ps
docker compose logs -f web
```

### Hornbill Alloy

```bash
ssh stefan@hornbill
cd /srv/services/alloy
docker compose restart
```

---

## Troubleshooting

### Status not updating

- Check cron: `crontab -l`
- Run manually: `python3 /srv/services/status/status.py`
- Check SSH key: `/home/stefan/.ssh/deploy_hornbill`

### Logs not appearing in Grafana

- Verify Alloy running: `docker ps | grep alloy`
- Check Loki connectivity: `curl -s http://100.102.199.98:3100/ready`
- Check Alloy logs: `docker logs alloy`

### App showing wrong state

- Verify Docker healthcheck in app's `docker-compose.yml`
- Check container: `docker inspect --format='{{.State.Health.Status}}' sgos-<app>-app`

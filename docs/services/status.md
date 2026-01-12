---
title: SGOS Status
sidebar_position: 4
description: Real-time status page for all SGOS applications
---

# SGOS Status

Real-time status page showing health, version, and deployment info for all SGOS applications on Hornbill.

## Access

| Property | Value |
|----------|-------|
| URL | https://sgos-status.sgl.as |
| Auth | Cloudflare Access (Google SSO) |
| Server | Toucan |
| Port | 3004 |

## Features

- Real-time health status with visual indicators
- App version display
- Last deployment time (relative)
- Direct links to GitHub commits
- **Scheduled jobs viewer** - shows all cron jobs across servers
- Auto-refresh every 60 seconds
- "All Systems Operational" summary banner

## Architecture

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

## Components

### status.py

Python script that SSHs to Hornbill and collects:
- Docker container health status
- Git commit info (hash, message, date)
- App metadata from `app.json`

Runs every minute via cron, outputs `apps.json`.

### index.html

Static HTML page with embedded JavaScript that:
- Fetches `apps.json` on load
- Renders app cards with status indicators
- Auto-refreshes every 60 seconds
- Shows summary banner (operational/degraded)

### nginx

Alpine nginx container serving static files on port 3004.

## Files

| File | Purpose |
|------|---------|
| `/srv/services/status/status.py` | Python collector script |
| `/srv/services/status/index.html` | Status page HTML |
| `/srv/services/status/apps.json` | Generated status data |
| `/srv/services/status/docker-compose.yml` | nginx container config |

## Cron Job

```bash
# stefan's crontab on Toucan
* * * * * /usr/bin/python3 /srv/services/status/status.py > /dev/null 2>&1
```

## JSON Schema

`apps.json` structure:

```json
{
  "generatedAt": "2026-01-12T20:14:04.338774",
  "apps": [
    {
      "name": "phone",
      "displayName": "sgos-phone",
      "description": "Voicemail processing and notification system",
      "version": "1.0.0",
      "state": "healthy",
      "domain": "phone.sgl.as",
      "deployedAt": "2026-01-12T20:04:28+02:00",
      "commit": "e4ca1df",
      "commitFull": "e4ca1df664297fbce3885c3222dee99aac673642",
      "commitMessage": "Update healthcheck...",
      "commitUrl": "https://github.com/sonnenglas/sgos-phone/commit/...",
      "repoUrl": "https://github.com/sonnenglas/sgos-phone"
    }
  ],
  "crons": [
    {
      "server": "toucan",
      "schedule": "0 3 * * *",
      "human": "Daily at 03:00",
      "command": "/srv/services/backups/backup-orchestrator.sh",
      "name": "backup-orchestrator"
    }
  ]
}
```

## Status States

| State | Indicator | Meaning |
|-------|-----------|---------|
| `healthy` | Green pulse | Docker reports container healthy |
| `unhealthy` | Red pulse | Docker reports container unhealthy |
| `starting` | Yellow pulse | Container starting, health check pending |
| `not-running` | Gray | Container not found or stopped |

## Management

```bash
# SSH to Toucan
ssh stefan@100.102.199.98

# View status
cd /srv/services/status
docker compose ps

# Restart nginx
docker compose restart

# Run collector manually
python3 status.py
cat apps.json | jq .

# View cron logs
grep status /var/log/syslog
```

## Troubleshooting

**Status not updating:**
- Check cron: `crontab -l`
- Run manually: `python3 /srv/services/status/status.py`
- Check SSH key: `/home/stefan/.ssh/deploy_hornbill`

**Page not loading:**
- Check nginx: `docker compose ps`
- Check Cloudflare tunnel status
- Verify port 3004 is listening

**App showing wrong state:**
- Verify Docker healthcheck in app's `docker-compose.yml`
- Check container: `docker inspect --format='{{.State.Health.Status}}' sgos-<app>-app`

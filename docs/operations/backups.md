---
title: Backups
sidebar_position: 2
description: Backup strategy and operations
---

# Backups

Two-stage backup: Toucan collects from all servers, then syncs offsite to Cloudflare R2.

## Architecture

```
Hornbill:
  /srv/apps/*/backups/           ← App backup outputs (local, 7 days)

       │ (rsync pull at 3 AM)
       ▼

Toucan:
  /srv/backups/staging/          ← Collected from all servers
  /srv/backups/status.json       ← Backup status

       │ (restic to R2)
       ▼

Cloudflare R2 (sonnenglas-backups) ← Offsite storage
```

## How It Works

1. Each app defines its own `backup.sh` script (knows what's critical)
2. `app.json` declares the backup output location
3. Toucan runs a nightly cron at 3 AM (`/srv/services/backups/backup-orchestrator.sh`)
4. Orchestrator SSHs to each server and runs the app backup scripts
5. Orchestrator pulls backup outputs via rsync to `/srv/backups/staging/`
6. Restic encrypts and syncs to Cloudflare R2

## Retention

| Location | Retention |
|----------|-----------|
| App server (local) | 7 days (managed by app backup.sh) |
| Toucan staging | Latest sync only |
| R2 (offsite) | 7 daily, 4 weekly, 3 monthly |

## What Gets Backed Up

| App | Data |
|-----|------|
| sgos-phone | PostgreSQL database, voicemail MP3s |

## Not Backed Up

- Redis (cache, regenerates)
- Loki logs (30-day retention in Loki itself)
- Docker images (pulled from registries)
- Source code (lives in GitHub)

## Files

| Path | Purpose |
|------|---------|
| `/srv/services/backups/.env` | R2 credentials, restic password |
| `/srv/services/backups/backup-orchestrator.sh` | Main orchestrator script |
| `/srv/backups/staging/` | Collected backups before R2 sync |
| `/srv/backups/status.json` | Latest backup status per app |
| `/srv/backups/backup.log` | Backup run log |

## Operations

### Check Backup Status

```bash
cat /srv/backups/status.json
```

### View Backup Log

```bash
tail -100 /srv/backups/backup.log
```

### List Snapshots in R2

```bash
cd /srv/services/backups
source .env
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY RESTIC_REPOSITORY RESTIC_PASSWORD
restic snapshots
```

### Trigger Manual Backup

```bash
/srv/services/backups/backup-orchestrator.sh
```

### Restore from Backup

```bash
cd /srv/services/backups
source .env
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY RESTIC_REPOSITORY RESTIC_PASSWORD

# List snapshots
restic snapshots

# Restore specific snapshot to temp directory
restic restore <snapshot-id> --target /tmp/restore

# Or restore latest
restic restore latest --target /tmp/restore
```

### Browse Snapshot Contents

```bash
restic ls latest
restic ls latest /srv/backups/staging/sgos-phone/
```

## Adding a New App

1. Create `backup.sh` in the app repo (runs on app server)
2. Add `scripts.backup` and `sgos.backup.output` to `app.json`
3. Add the app to `/srv/services/backups/backup-orchestrator.sh` on Toucan

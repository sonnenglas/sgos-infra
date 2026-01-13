---
title: Backups
sidebar_position: 4
description: Backup strategy and restore procedures
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

---

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

---

## Restore Procedures

### Setup

```bash
cd /srv/services/backups
source .env
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY RESTIC_REPOSITORY RESTIC_PASSWORD
```

### List Available Snapshots

```bash
restic snapshots

# Output:
# ID        Time                 Host    Tags
# a1b2c3d4  2026-01-10 03:00:05  toucan
# e5f6g7h8  2026-01-11 03:00:03  toucan
# i9j0k1l2  2026-01-12 03:00:04  toucan
```

### Browse Snapshot Contents

```bash
restic ls latest
restic ls latest /srv/backups/staging/sgos-phone/
```

---

## Restore Examples

### Example 1: Restore Phone Database

```bash
# On Toucan - prepare restic
cd /srv/services/backups
source .env
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY RESTIC_REPOSITORY RESTIC_PASSWORD

# List available snapshots
restic snapshots

# Restore latest to temp directory
restic restore latest --target /tmp/restore --include "sgos-phone"

# Copy to Hornbill
scp /tmp/restore/srv/backups/staging/sgos-phone/database.sql stefan@hornbill:/tmp/

# On Hornbill - restore database
ssh stefan@hornbill
cd /srv/apps/sgos-phone

# Stop app, keep database running
docker compose stop phone

# Restore (drops and recreates)
docker exec -i sgos-phone-db psql -U postgres -d phone < /tmp/database.sql

# Restart app
docker compose up -d phone

# Cleanup
rm /tmp/database.sql
```

### Example 2: Restore Specific Voicemail Files

```bash
# On Toucan
cd /srv/services/backups
source .env
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY RESTIC_REPOSITORY RESTIC_PASSWORD

# Browse to find specific files
restic ls latest /srv/backups/staging/sgos-phone/voicemails/

# Restore just voicemails directory
restic restore latest --target /tmp/restore --include "sgos-phone/voicemails"

# Copy specific files to Hornbill
scp /tmp/restore/srv/backups/staging/sgos-phone/voicemails/*.mp3 \
    stefan@hornbill:/srv/apps/sgos-phone/data/voicemails/
```

### Example 3: Restore from Specific Date

```bash
# List snapshots with timestamps
restic snapshots

# Restore from January 10th (using snapshot ID)
restic restore a1b2c3d4 --target /tmp/restore-jan10
```

### Example 4: Point-in-Time Database Restore

For PostgreSQL with WAL archiving (if configured):

```bash
# Stop the app
docker compose stop phone

# Restore base backup
docker exec -i sgos-phone-db psql -U postgres -d phone < /tmp/database.sql

# App will replay any WAL logs on startup
docker compose up -d phone
```

**Note:** Currently, backups are daily SQL dumps. For point-in-time recovery, WAL archiving would need to be configured.

---

## Backup Verification

### Verify Backup Integrity

```bash
cd /srv/services/backups
source .env
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY RESTIC_REPOSITORY RESTIC_PASSWORD

# Check repository integrity
restic check

# Verify specific snapshot can be restored
restic restore latest --target /tmp/verify-test --verify
rm -rf /tmp/verify-test
```

### Verify Database Dump

```bash
# Restore and check SQL file is valid
restic restore latest --target /tmp/verify --include "sgos-phone/database.sql"

# Check file size (should be non-zero)
ls -lh /tmp/verify/srv/backups/staging/sgos-phone/database.sql

# Optionally restore to test database
docker exec -i sgos-phone-db psql -U postgres -c "CREATE DATABASE phone_test;"
docker exec -i sgos-phone-db psql -U postgres -d phone_test < /tmp/verify/.../database.sql
docker exec -i sgos-phone-db psql -U postgres -c "DROP DATABASE phone_test;"
```

---

## Adding a New App

1. Create `backup.sh` in the app repo (runs on app server)
2. Add `scripts.backup` and `sgos.backup.output` to `app.json`
3. Add the app to `/srv/services/backups/backup-orchestrator.sh` on Toucan

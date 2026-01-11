---
title: Backups
sidebar_position: 2
description: Backup strategy
---

# Backups

Two-stage backup: Toucan collects from all servers, then syncs offsite to Cloudflare R2.

## How It Works

1. Each app defines its own `backup.sh` script (knows what's critical)
2. `app.json` declares the backup command
3. Toucan runs a nightly cron that executes each app's backup
4. Toucan pulls backup output via SSH/rsync
5. Restic syncs everything to Cloudflare R2

## Retention

| Location | Retention |
|----------|-----------|
| Toucan (local) | 7 days |
| R2 (offsite) | 7 daily, 4 weekly, 3 monthly |

## What Gets Backed Up

- App databases and critical files (defined by each app)
- GlitchTip database

## Not Backed Up

- Redis (cache, regenerates)
- Loki logs (30-day retention in Loki itself)
- Docker images (pulled from registries)
- Source code (lives in GitHub)

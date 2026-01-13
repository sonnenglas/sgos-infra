---
title: App Schema (app.json)
sidebar_position: 2
description: Standard configuration file for SGOS applications
---

# App Schema (app.json)

Every SGOS application includes an `app.json` file that defines metadata and configuration. Based on [Heroku's app.json](https://devcenter.heroku.com/articles/app-json-schema) with SGOS-specific extensions.

## Fields

### Core

| Field | Description |
|-------|-------------|
| `name` | System name (`sgos-<name>`) |
| `description` | What the app does |
| `version` | Current version (semver) |
| `migration` | Migration type: `none`, `safe`, or `breaking` |
| `repository` | GitHub URL |

### Migration Field

| Value | Meaning | Rollback Safe? |
|-------|---------|----------------|
| `none` | No database changes | Yes |
| `safe` | Additive only (new columns/tables) | Yes |
| `breaking` | Destructive changes | No — needs DB restore |

### Environment (`env`)

Documents required environment variables. Actual values go in `.env`.

### Scripts

| Script | Description |
|--------|-------------|
| `postdeploy` | Run after deployment (migrations) |
| `backup` | Backup command (called by Toucan) |

### SGOS Extensions (`sgos`)

| Field | Description |
|-------|-------------|
| `domain` | Public domain |
| `dependencies` | Other SGOS apps this app depends on |
| `backup.output` | Directory for backup files |
| `apis` | API endpoints (private, internal, public) |

## Required Files

Every SGOS app must have these files in its repository:

| File | Description |
|------|-------------|
| `app.json` | App metadata (this schema) |
| `CHANGELOG.md` | Change history ([Keep a Changelog](https://keepachangelog.com/) format) |
| `.env.sops` | Encrypted secrets (SOPS) |
| `.sops.yaml` | SOPS configuration |
| `docker-compose.yml` | Container configuration |

## Docker Network Requirement

Apps must join the `sgos` external network for the centralized proxy to reach them:

```yaml
services:
  myapp:
    build: .
    container_name: sgos-myapp
    networks:
      - sgos
      - internal  # optional, for DB isolation

networks:
  sgos:
    external: true
  internal:  # optional
    driver: bridge
```

This enables the maintenance mode proxy. See [Deployment](../infrastructure/deployment) for details.

## Health Check Requirement

Apps must define a Docker healthcheck so the deployment script can verify the app started successfully. The deployment waits for Docker to report the container as "healthy" before exiting maintenance mode.

```yaml
services:
  myapp:
    build: .
    container_name: sgos-myapp
    healthcheck:
      test: ["CMD", "curl", "-sf", "http://localhost:8000/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 60s  # Grace period for migrations
    # ...
```

| Parameter | Description |
|-----------|-------------|
| `test` | Command to check health (must return 0 for healthy) |
| `interval` | Time between checks |
| `timeout` | Max time for check to complete |
| `retries` | Consecutive failures before marking unhealthy |
| `start_period` | Grace period on startup (failures don't count) |

The app must expose a `/health` endpoint that returns HTTP 200 when ready to serve traffic. This endpoint should verify database connectivity and other dependencies.

## Location

Lives at `/srv/apps/sgos-<name>/app.json` on the server, and in the git repository.

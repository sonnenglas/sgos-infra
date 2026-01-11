---
title: App Schema (app.json)
sidebar_position: 3
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

## Location

Lives at `/srv/apps/sgos-<name>/app.json` on the server, and in the git repository.

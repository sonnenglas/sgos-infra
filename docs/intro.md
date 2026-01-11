---
title: SGOS Documentation
sidebar_position: 1
slug: /
---

# SGOS Documentation

Welcome to the Sonnenglas Operating System (SGOS) infrastructure documentation.

## What is SGOS?

SGOS is an API-first, modular operating system for Sonnenglas business operations. All in-house developed apps communicate through well-defined APIs, enabling an agentic, AI-driven business management approach.

## Quick Links

| Topic | Description |
|-------|-------------|
| [SGOS Concept](./concept/sgos) | The vision and architecture of SGOS |
| [API Strategy](./architecture/api-strategy) | API versioning and contracts |
| [App Schema](./architecture/app-schema) | Standard app.json configuration |
| [Deployment](./operations/deployment) | How to deploy apps |
| [Backups](./operations/backups) | Backup strategy and restore procedures |

## Infrastructure Overview

Two-server setup on Netcup in Nuremberg, connected via Tailscale mesh network, with external access through Cloudflare Tunnel.

| Server | Role | Purpose |
|--------|------|---------|
| Toucan | Control | Monitoring, GlitchTip, Backup orchestration |
| Hornbill | Applications | SGOS business apps |

See [Architecture Overview](./architecture/overview) for server specs and network topology.

## Tech Stack

- **Servers:** Netcup VPS (Ubuntu 24.04)
- **Networking:** Tailscale, Cloudflare Tunnel
- **Deployments:** Docker Compose + Traefik (source-based)
- **App Config:** app.json (Heroku-compatible with SGOS extensions)
- **Monitoring:** Grafana + Loki + Alloy
- **Error Tracking:** GlitchTip
- **Backups:** Toucan (local) → Cloudflare R2 (offsite) via Restic

## Services

| Service | URL |
|---------|-----|
| Grafana | http://toucan:3001 (Tailscale) |
| GlitchTip | https://glitchtip.sgl.as |

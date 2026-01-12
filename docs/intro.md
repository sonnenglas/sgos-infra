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
| [Secrets](./operations/secrets) | Encrypting secrets with SOPS |
| [Backups](./operations/backups) | Backup strategy and restore procedures |

---

## System Overview

### 1. Infrastructure

Two Netcup VPS servers in Nuremberg, connected via Tailscale mesh network, with external access through Cloudflare Tunnel.

| Server | Role | Tailscale IP | Purpose |
|--------|------|--------------|---------|
| Toucan | Control plane | 100.86.22.9 | Orchestration, monitoring, shared services |
| Hornbill | App server | 100.67.57.25 | SGOS business applications |

See [Architecture Overview](./architecture/overview) for server specs and network topology.

### 2. Platform Services

Internal services that keep the infrastructure running. Not directly user-facing.

| Service | Server | Description |
|---------|--------|-------------|
| Webhook | Toucan | GitHub webhook receiver for auto-deployments |
| Watchtower | Both | Automatic container updates |
| Cloudflare Tunnel | Both | Secure external access (cloudflared) |
| Beszel Agent | Hornbill | Metrics collection agent |
| Dozzle Agent | Hornbill | Log collection agent |

### 3. Shared Services

Services used across all SGOS apps for monitoring, identity, and operations.

| Service | URL | Server | Description |
|---------|-----|--------|-------------|
| Dashboard | [dashboard.sgl.as](https://dashboard.sgl.as) | Toucan | Homepage with links to all services |
| Beszel | [beszel.sgl.as](https://beszel.sgl.as) | Toucan | Server monitoring |
| Dozzle | [dozzle.sgl.as](https://dozzle.sgl.as) | Toucan | Docker logs viewer |
| GlitchTip | [glitchtip.sgl.as](https://glitchtip.sgl.as) | Toucan | Error tracking |
| PocketID | [id.sgl.as](https://id.sgl.as) | Toucan | OIDC identity provider |
| SGOS Docs | [sgos-infra.sgl.as](https://sgos-infra.sgl.as) | Toucan | This documentation |

### 4. SGOS Applications

Business applications built on the SGOS platform.

| App | URL | Server | Status | Description |
|-----|-----|--------|--------|-------------|
| Phone | [phone.sgl.as](https://phone.sgl.as) | Hornbill | ✅ Live | Voicemail processing & notifications |

**Planned:**

| App | Server | Status | Description |
|-----|--------|--------|-------------|
| Docflow | TBD | 🚧 Development | Document management system |

---

## Tech Stack

- **Servers:** Netcup VPS (Ubuntu 24.04)
- **Networking:** Tailscale, Cloudflare Tunnel
- **Deployments:** Docker Compose (source-based)
- **App Config:** app.json (Heroku-compatible with SGOS extensions)
- **Monitoring:** Beszel (server metrics) + Dozzle (Docker logs)
- **Error Tracking:** GlitchTip
- **Identity:** PocketID (OIDC provider)
- **Secrets:** SOPS + age encryption
- **Backups:** Toucan (local) → Cloudflare R2 (offsite) via Restic

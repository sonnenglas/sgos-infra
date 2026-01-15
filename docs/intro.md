---
title: SGOS Documentation
sidebar_position: 1
slug: /
---

# SGOS - Sonnenglas Operating System

## What is SGOS?

SGOS is the internal operating system for Sonnenglas. It defines how we operate globally as a company.

Think of it as an **in-house ERP system**, but built differently:

- **Modular architecture** — Small, focused apps that do one thing well
- **API-first design** — All apps communicate through well-defined APIs
- **Data ownership** — We fully own our data and expose it through APIs
- **AI-native** — APIs are designed to be consumed by UIs, LLMs, and autonomous agents

### Why build our own?

The innovation is in the approach: **APIs are contracts between apps**. This means:

- Any app can consume data from any other app
- LLMs can read and act on business data through the same APIs humans use
- Agents can orchestrate workflows across multiple systems
- We're not locked into vendor ecosystems or data formats

This is why we don't use an existing ERP — they weren't designed for an AI-native world.

---

## SGOS Applications

All business applications built on the SGOS platform.

| App | Description | Domain | Status |
|-----|-------------|--------|--------|
| **Phone** | Voicemail processing & notifications · `sgos-phone` | [phone.sgl.as](https://phone.sgl.as) | 🟢 Live |
| **Ikhaya** | Internal knowledge base · `sgos-ikhaya` | [ikhaya.sgl.as](https://ikhaya.sgl.as) | 🟢 Live |
| **Docflow** | Document management (invoices, contracts) · `sgos-docflow` | [docflow.sgl.as](https://docflow.sgl.as) | 🟡 Beta |
| **Ufudu** | Warehouse fulfillment (pick/pack) · `sgos-ufudu` | [ufudu.sgl.as](https://ufudu.sgl.as) | 🟡 Beta |
| **Accounting** | Financial transactions, VAT, exports · `sgos-accounting` | [accounting.sgl.as](https://accounting.sgl.as) | 🟠 Alpha |
| **Inventory** | Stock management & quantities · `sgos-inventory` | [inventory.sgl.as](https://inventory.sgl.as) | 🟠 Alpha |
| **Baobab** | Product master, brands, listings · `sgos-baobab` | [baobab.sgl.as](https://baobab.sgl.as) | 🔵 Concept |
| **Directory** | User directory for all apps · `sgos-directory` | [directory.sgl.as](https://directory.sgl.as) | 🟠 Alpha |
| **Xhosa** | Order management, CRM, invoicing · `sgos-xhosa` | [xhosa.sgl.as](https://xhosa.sgl.as) | 🔵 Concept |
| **Soup** | Central to-do lists, task management · `sgos-soup` | [soup.sgl.as](https://soup.sgl.as) | 🔵 Concept |
| **Anansi** | Internal AI chatbot & assistant · `sgos-anansi` | [anansi.sgl.as](https://anansi.sgl.as) | 🔵 Concept |
| **Clock** | Time tracking & attendance · `sgos-clock` | [clock.sgl.as](https://clock.sgl.as) | 🔵 Concept |
| **MRP** | Manufacturing & production planning · `sgos-mrp` | [mrp.sgl.as](https://mrp.sgl.as) | ⚪ Planned |

See [Apps Overview](./apps/overview) for detailed descriptions and API documentation.

---

## Infrastructure

### Servers

Two Netcup VPS servers in Nuremberg, connected via Tailscale mesh network, with external access through Cloudflare Tunnel.

| Server | Role | Tailscale IP | Purpose |
|--------|------|--------------|---------|
| **Hornbill** | App Server | 100.67.57.25 | Runs all SGOS business applications |
| **Toucan** | Control Plane | 100.102.199.98 | Orchestration, monitoring, backups, deployments |

### Shared Services

Services that support the SGOS platform.

| Service | URL | Purpose | Status |
|---------|-----|---------|--------|
| SGOS Status | [sgos-status.sgl.as](https://sgos-status.sgl.as) | Real-time app health dashboard | 🟢 Live |
| Grafana | [grafana.sgl.as](https://grafana.sgl.as) | Log aggregation (Loki) | 🟢 Live |
| GlitchTip | [glitchtip.sgl.as](https://glitchtip.sgl.as) | Error tracking | 🟢 Live |
| PocketID | [id.sgl.as](https://id.sgl.as) | Identity provider (OIDC) | 🟢 Live |
| Sangoma | [sangoma.sgl.as](https://sangoma.sgl.as) | Automated error analysis & fix proposals | 🔵 Concept |
| Message Bus | — | Event bus for async communication | 🔵 Concept |

### Tech Stack

| Component | Technology |
|-----------|------------|
| **Servers** | Netcup VPS (Ubuntu 24.04) |
| **Networking** | Tailscale mesh + Cloudflare Tunnel |
| **Deployments** | Docker Compose (source-based, via GitHub webhooks) |
| **App Config** | app.json (Heroku-compatible with SGOS extensions) |
| **Secrets** | SOPS + age encryption |
| **Backups** | Restic to Cloudflare R2 |
| **Monitoring** | Grafana + Loki (logs), GlitchTip (errors) |
| **Identity** | Cloudflare Zero Trust + PocketID |

---

## Documentation

### Apps

- [Apps Overview](./apps/overview) — Detailed app descriptions and connections
- [App Schema](./apps/app-schema) — Standard app.json configuration
- [API Strategy](./apps/api-strategy) — API versioning and contracts

### Infrastructure

- [Architecture](./infrastructure/architecture) — Server specs, network topology
- [Deployment](./infrastructure/deployment) — How to deploy and update apps
- [Backups](./infrastructure/backups) — Backup strategy and restore procedures
- [Secrets](./infrastructure/secrets) — Encrypting secrets with SOPS
- [Cloudflare](./infrastructure/cloudflare) — Tunnel, DNS, and Access configuration
- [Monitoring](./infrastructure/monitoring) — Grafana, Loki, GlitchTip, Status page
- [Disaster Recovery](./infrastructure/disaster-recovery) — Recovery procedures
- [Authentication](./infrastructure/authentication) — Zero Trust and OIDC flows

---

## Quick Reference

### System Naming Convention

All SGOS applications follow a consistent naming pattern:

| Component | Format | Example |
|-----------|--------|---------|
| Repository | `sgos-<name>` | `sgos-phone` |
| Container | `sgos-<name>-app` | `sgos-phone-app` |
| Directory | `/srv/apps/sgos-<name>/` | `/srv/apps/sgos-phone/` |
| Domain | `<name>.sgl.as` | `phone.sgl.as` |

### Access

All services are behind Cloudflare Zero Trust. Authentication options:
- Google Workspace login
- PocketID (passkeys/WebAuthn)
- Service tokens (for API access)

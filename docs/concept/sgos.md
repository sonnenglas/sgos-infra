---
title: SGOS Concept
sidebar_position: 1
description: The vision and architecture of the Sonnenglas Operating System
---

# SGOS - Sonnenglas Operating System

> The new API-first, modular Sonnenglas Operating System (SGOS). All in-house developed apps that communicate with each other over APIs to allow for an agentic, AI-driven business management.

## Table of Contents

- [System Names](#system-names)
- [Business Applications](#business-applications)
- [Infrastructure Systems](#infrastructure-systems)
- [External Systems](#external-systems)
- [Architecture Notes](#architecture-notes)

---

## System Names

All SGOS applications follow a consistent naming convention:

| App | System Name | Domain |
|-----|-------------|--------|
| Directory | `sgos-directory` | [directory.sgl.as](https://directory.sgl.as) |
| Docflow | `sgos-docflow` | [docflow.sgl.as](https://docflow.sgl.as) |
| Accounting | `sgos-accounting` | [accounting.sgl.as](https://accounting.sgl.as) |
| Inventory | `sgos-inventory` | [inventory.sgl.as](https://inventory.sgl.as) |
| MRP | `sgos-mrp` | [mrp.sgl.as](https://mrp.sgl.as) |
| Xhosa | `sgos-xhosa` | [xhosa.sgl.as](https://xhosa.sgl.as) |
| Ufudu | `sgos-ufudu` | [ufudu.sgl.as](https://ufudu.sgl.as) |
| Human in the Soup | `sgos-soup` | [soup.sgl.as](https://soup.sgl.as) |
| Anansi | `sgos-anansi` | [anansi.sgl.as](https://anansi.sgl.as) |
| Ikhaya | `sgos-ikhaya` | [ikhaya.sgl.as](https://ikhaya.sgl.as) |
| Phone | `sgos-phone` | [phone.sgl.as](https://phone.sgl.as) |
| Control | `sgos-ctrl` | [ctrl.sgl.as](https://ctrl.sgl.as) |
| Message Bus | `sgos-bus` | [bus.sgl.as](https://bus.sgl.as) |
| Identity | `sgos-id` | [id.sgl.as](https://id.sgl.as) |

The system name is used consistently for:
- GitHub repository name
- Docker image name
- Container name
- Folder name (`/srv/apps/sgos-<app>/`)
- Compose project name

---

## Business Applications

### Directory

> **System:** `sgos-directory`
> **Domain:** [directory.sgl.as](https://directory.sgl.as)
>
> A user directory exposed as a simple API so all apps know: Who is who. Central management of users and their attributes. Apps still manage access control and permissions individually.

| | |
|---|---|
| **Input** | UI, Google Workspace Sync |
| **Output** | Private API (for UI), Internal API (for other apps) |
| **Connections** | All modules |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://directory.sgl.as/api/...` |
| Company Internal | Yes | `https://directory.sgl.as/api/int/v1/...` |
| Public | No | — |

---

### Docflow (Documents)

> **System:** `sgos-docflow`
> **Domain:** [docflow.sgl.as](https://docflow.sgl.as)
>
> All incoming documents as structured data. Mail, contracts, invoices. Paperless-NGX on steroids.

| | |
|---|---|
| **Input** | Users (upload documents), APIs (email, dropscan, etc.) |
| **Output** | UI, API, Bank Files (batch payments) |
| **Connections** | Human in the Soup, Accounting |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://docflow.sgl.as/api/...` |
| Company Internal | Yes | `https://docflow.sgl.as/api/int/v1/...` |
| Public | No | — |

---

### Accounting

> **System:** `sgos-accounting`
> **Domain:** [accounting.sgl.as](https://accounting.sgl.as)
>
> Accounting system as a single source of truth for all business matters that are financially relevant.

| | |
|---|---|
| **Input** | Financial transactions (Banks, Stripe), API, Users (bank feeds, manual entries) |
| **Output** | API, Exports (VAT, DATEV) |
| **Connections** | Human in the Soup, Docflow, Xhosa, DATEV |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://accounting.sgl.as/api/...` |
| Company Internal | Yes | `https://accounting.sgl.as/api/int/v1/...` |
| Public | No | — |

---

### Inventory

> **System:** `sgos-inventory`
> **Domain:** [inventory.sgl.as](https://inventory.sgl.as)
>
> Single source of truth for all physical stock movements. Centralized product management (what exists, its attributes).

| | |
|---|---|
| **Input** | UI (stock movements), API |
| **Output** | UI, API |
| **Connections** | Xhosa, Accounting |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://inventory.sgl.as/api/...` |
| Company Internal | Yes | `https://inventory.sgl.as/api/int/v1/...` |
| Public | No | — |

---

### MRP (Manufacturing)

> **System:** `sgos-mrp`
> **Domain:** [mrp.sgl.as](https://mrp.sgl.as)
>
> Manufacturing and production with flat-file architecture and lightweight database. Strongly connected with Inventory.
>
> - Finished products and subassemblies defined as dependency files (YAML/JSON)
> - Work orders managed in lightweight DB
> - Pushes actual production to Inventory
> - Planning and organisational UI: "What do we need to manufacture and when?"
> - Tracks production with barcode scanners (serial numbers, etc.)
> - Process flows exposed as UI (SOPs, Incoming Goods, Quality Control)

| | |
|---|---|
| **Input** | UI (stock movements), API |
| **Output** | UI, API |
| **Connections** | Xhosa, Accounting, Human in the Soup |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://mrp.sgl.as/api/...` |
| Company Internal | Yes | `https://mrp.sgl.as/api/int/v1/...` |
| Public | No | — |

---

### Xhosa (Order Management)

> **System:** `sgos-xhosa`
> **Domain:** [xhosa.sgl.as](https://xhosa.sgl.as)
>
> Single source of truth for all orders and their state, including VAT calculation, invoicing. Also handles forecasting, demand planning, and serves as partial CRM (all customer data).

| | |
|---|---|
| **Input** | Website (via Stripe), Amazon Import, Platform Sales Channels, Partner Portal (B2B), Users (staff) |
| **Output** | API |
| **Connections** | Human in the Soup, Accounting, Ufudu, Inventory, Stripe |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://xhosa.sgl.as/api/...` |
| Company Internal | Yes | `https://xhosa.sgl.as/api/int/v1/...` |
| Public | No | — |

---

### Ufudu (Fulfillment)

> **System:** `sgos-ufudu`
> **Domain:** [ufudu.sgl.as](https://ufudu.sgl.as)
>
> Pick/Pack fulfillment system for warehouses. Mobile SPA with barcode scanning to guide fulfillment operations. Runs on Android devices with connected barcode scanners.

| | |
|---|---|
| **Input** | API (orders) |
| **Output** | API |
| **Connections** | Human in the Soup, Inventory, Xhosa |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://ufudu.sgl.as/api/...` |
| Company Internal | Yes | `https://ufudu.sgl.as/api/int/v1/...` |
| Public | No | — |

---

### Human in the Soup

> **System:** `sgos-soup`
> **Domain:** [soup.sgl.as](https://soup.sgl.as)
>
> General shared todo list where all systems can report when they need a human to provide data or resolve matters. Example: Accounting's LLM agent needs a new bank feed → creates a todo here.
>
> Also serves as company-wide process and project management overview with Kanban-style UI.

| | |
|---|---|
| **Input** | API (LLMs use it) |
| **Output** | API (callback URLs), UI (task management) |
| **Connections** | All systems |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://soup.sgl.as/api/...` |
| Company Internal | Yes | `https://soup.sgl.as/api/int/v1/...` |
| Public | No | — |

---

### Anansi (AI Assistant)

> **System:** `sgos-anansi`
> **Domain:** [anansi.sgl.as](https://anansi.sgl.as)
>
> Internal general AI assistant connected to all systems. Exposed as chatbot and API. Consumes all important information and stores in vector database for retrieval. Helps internally and with customer support.
>
> All knowledge is scoped and classified from public to internal.

| | |
|---|---|
| **Input** | All systems via API (push or pull, jobs or tool calls) |
| **Output** | Internal Chatbot, External Chat (website), API |
| **Connections** | All systems |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://anansi.sgl.as/api/...` |
| Company Internal | Yes | `https://anansi.sgl.as/api/int/v1/...` |
| Public | No | — |

---

### Ikhaya (Knowledge Base)

> **System:** `sgos-ikhaya`
> **Domain:** [ikhaya.sgl.as](https://ikhaya.sgl.as)
>
> Internal knowledge base and blog (Docusaurus project). Contains all company knowledge. Embeds Anansi as a chatbot.

| | |
|---|---|
| **Input** | API, Users |
| **Output** | UI, Google Chat (notifications) |
| **Connections** | Anansi |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://ikhaya.sgl.as/api/...` |
| Company Internal | Yes | `https://ikhaya.sgl.as/api/int/v1/...` |
| Public | No | — |

---

### Phone

> **System:** `sgos-phone`
> **Domain:** [phone.sgl.as](https://phone.sgl.as)
>
> Phone call logging and transcription system. Records calls, transcribes them, and provides summaries.

| | |
|---|---|
| **Input** | Placetel API (phone calls) |
| **Output** | UI, API |
| **Connections** | Anansi |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://phone.sgl.as/api/...` |
| Company Internal | Yes | `https://phone.sgl.as/api/int/v1/...` |
| Public | No | — |

---

## Infrastructure Systems

### Ctrl (Control Server)

> **System:** `sgos-ctrl`
> **Domain:** [ctrl.sgl.as](https://ctrl.sgl.as)
>
> Centralised control server that monitors and aggregates all services and apps. Has all logfiles, exceptions, coordinates backups, etc. An "agent" runs there to observe errors and might have read access to systems and code to investigate and propose fixes.
>
> Daily backups with offsite copy.

| | |
|---|---|
| **Input** | Grafana/Loki, GlitchTip, Container Monitoring, Backups |
| **Output** | UI (dashboard), Human in the Soup (raise tasks) |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://ctrl.sgl.as/api/...` |
| Company Internal | Yes | `https://ctrl.sgl.as/api/int/v1/...` |
| Public | No | — |

---

### Message Bus

> **System:** `sgos-bus`
> **Domain:** [bus.sgl.as](https://bus.sgl.as)
>
> Event bus for async communication between systems. Simple Postgres-backed append-only events table exposed via API. Systems publish events when things happen, other systems subscribe. Reduces polling, enables loose coupling, provides audit trail.
>
> Events follow a shared dictionary/schema.

| | |
|---|---|
| **Input** | API (all systems publish) |
| **Output** | API (poll or webhooks) |
| **Connections** | All systems |

**APIs:**

| API | Available | URL |
|-----|-----------|-----|
| Private | Yes | `https://bus.sgl.as/api/...` |
| Company Internal | Yes | `https://bus.sgl.as/api/int/v1/...` |
| Public | No | — |

**Event Dictionary:**

| Event | Source |
|-------|--------|
| `order.created` | Xhosa |
| `order.shipped` | Ufudu |
| `stock.movement` | Inventory |
| `stock.low` | Inventory |
| `invoice.received` | Docflow |
| `payment.matched` | Accounting |
| `production.completed` | MRP |
| `task.created` | Human in the Soup |

---

### Identity (Pocket ID)

> **System:** `sgos-id`
> **Domain:** [id.sgl.as](https://id.sgl.as)
>
> Self-hosted identity provider using Pocket ID. Provides authentication for users without Google accounts. Supports passkeys/WebAuthn.

| | |
|---|---|
| **Input** | Users (login) |
| **Output** | OIDC Provider |
| **Connections** | Cloudflare Zero Trust, all apps |

---

## External Systems

These systems are not part of the SGOS namespace (not internally developed or hosted externally). External systems use the `sonnenglas.net` domain.

### Website

> **Domain:** [sonnenglas.net](https://sonnenglas.net)
>
> Public website and e-commerce shop. Static pages using Astro.js with dynamic islands. Connects to product catalogue, checkout via Stripe. Orders end up in Xhosa. Runs on Cloudflare Pages.

| | |
|---|---|
| **Input** | Public website |
| **Output** | Orders to Xhosa (via Stripe) |
| **Connections** | Xhosa, Stripe, Anansi |

---

### Partner Portal

> **Domain:** [partner.sonnenglas.net](https://partner.sonnenglas.net)
>
> Portal for resellers to login and manage their orders.

| | |
|---|---|
| **Input** | Public website (with login) |
| **Output** | Orders to Xhosa |
| **Connections** | Xhosa |

---

## Architecture Notes

### UI

UI means a general interface for humans to interact with. May include notifications, emails, etc.

### Identity & Access Control

- All apps behind Tailscale, only expose 80/443 over Cloudflare Tunnel
- Access control via Cloudflare Zero Trust (Google Login, Pocket ID, Service Auth for APIs, app-specific API keys with scopes)
- Service-to-service communication within Tailscale internal network

**User Identity:**
- Google Workspace Login
- Pocket ID ([id.sgl.as](https://id.sgl.as))
- Directory available to all apps via Directory API

### Networking

#### Tailscale

All servers use Tailscale for internal network with MagicDNS and internal APIs.

| | |
|---|---|
| **Tailnet** | `tail5b811.ts.net` |

#### Cloudflare Tunnel

Cloudflare Zero Trust tunnels expose apps while keeping servers isolated.

### Modularity

While all tools are listed separately, they can also be subpages/modules in a single UI layer. The above describes the structural setup, not necessarily the presentation to users. Most systems can run on the same server in Docker containers.

### API Conventions

All systems are isolated and run in their own containers. They expose all functionality through APIs. Each module can have up to 3 different APIs following these conventions.

> **Full documentation:** See [API Strategy](../architecture/api-strategy) for versioning, contracts, and implementation details.

#### URL Structure

| API Type | API URL | Documentation URL | OpenAPI Spec |
|----------|---------|-------------------|--------------|
| Private | `/api/...` | `/api/docs` | `/api/openapi.json` |
| Company Internal | `/api/int/v1/...` | `/api/int/v1/docs` | `/api/int/v1/openapi.json` |
| Public | `/api/pub/v1/...` | `/api/pub/v1/docs` | `/api/pub/v1/openapi.json` |

#### Private API (all apps have it)

> **URL:** `/api/...`
> **Docs:** `/api/docs`
>
> The API used internally by the application itself (e.g., its own frontend). Changes often during development, no external consumers or dependencies. No versioning needed. Documentation still generated.

#### Company Internal API (most apps have it)

> **URL:** `/api/int/v1/...`
> **Docs:** `/api/int/v1/docs`
> **Contract:** `openapi/internal-v1.json` (committed to repo)
>
> The API exposed within the company. Has external dependencies, must be versioned and stable. Has its own stable mapping (not direct database mapping). Only exposes endpoints needed for internal company usage.

#### Public External API (optional)

> **URL:** `/api/pub/v1/...`
> **Docs:** `/api/pub/v1/docs`
> **Contract:** `openapi/public-v1.json` (committed to repo)
>
> The API exposed to the outside world. Has external dependencies, must be versioned and stable. Has its own stable mapping (not direct database mapping).

#### API Contract Strategy

For versioned APIs (internal and public):
- **Code defines the API** — Pydantic schemas are the source of truth
- **FastAPI generates OpenAPI** — Automatic documentation from code
- **Export and commit** — `openapi.json` is versioned in git as the contract
- **Test against spec** — Verify API matches the contract using `schemathesis`

**Note:** We currently don't see a need for public APIs - this is conceptual. Any public API would likely be a subset or permission control layer on top of the internal API.

---

## Infrastructure

| Provider | Service |
|----------|---------|
| **Hosting** | Netcup VPS |
| **Email** | Postmark and/or Inbound.new |

### Servers

#### Toucan (Control)

| | |
|---|---|
| **Role** | CTRL Server |
| **Hostname** | [toucan.sgl.as](https://toucan.sgl.as) |
| **Hoster** | Netcup Nuremberg |
| **Specs** | 8C CPU, 16 GB RAM, 1 TB SSD |
| **Public IP** | `152.53.160.251` |
| **Tailscale IP** | `100.102.199.98` |
| **Tailscale DNS** | `toucan` / `toucan.tail5b811.ts.net` |

#### Hornbill (Apps)

| | |
|---|---|
| **Role** | App Server |
| **Hostname** | [hornbill.sgl.as](https://hornbill.sgl.as) |
| **Hoster** | Netcup Nuremberg |
| **Specs** | 12C CPU, 32 GB RAM, 1 TB SSD |
| **Public IP** | `159.195.68.119` |
| **Tailscale IP** | `100.67.57.25` |
| **Tailscale DNS** | `hornbill` / `hornbill.tail5b811.ts.net` |

---
title: Apps Overview
sidebar_position: 1
description: Detailed descriptions of all SGOS applications
---

# SGOS Applications

All SGOS applications are modular, API-first services that work together to run Sonnenglas operations.

## Business Applications

### Phone

| Property | Value |
|----------|-------|
| **System** | `sgos-phone` |
| **Domain** | [phone.sgl.as](https://phone.sgl.as) |
| **Status** | Live |

Voicemail processing and notification system. Records phone calls, transcribes them using AI, and sends notifications with summaries.

| | |
|---|---|
| **Input** | Placetel API (phone calls) |
| **Output** | UI, API |
| **Connections** | Anansi |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Xhosa (Order Management)

| Property | Value |
|----------|-------|
| **System** | `sgos-xhosa` |
| **Domain** | [xhosa.sgl.as](https://xhosa.sgl.as) |
| **Status** | Planned |

Single source of truth for all orders and their state. Handles VAT calculation, invoicing, forecasting, demand planning, and serves as partial CRM (all customer data).

| | |
|---|---|
| **Input** | Website (via Stripe), Amazon Import, Platform Sales Channels, Partner Portal (B2B), Users (staff) |
| **Output** | API |
| **Connections** | Human in the Soup, Accounting, Ufudu, Inventory, Stripe |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Docflow (Documents)

| Property | Value |
|----------|-------|
| **System** | `sgos-docflow` |
| **Domain** | [docflow.sgl.as](https://docflow.sgl.as) |
| **Status** | Live |

All incoming documents as structured data. Mail, contracts, invoices. Think Paperless-NGX on steroids.

| | |
|---|---|
| **Input** | Users (upload documents), APIs (email, dropscan, etc.) |
| **Output** | UI, API, Bank Files (batch payments) |
| **Connections** | Human in the Soup, Accounting |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Accounting

| Property | Value |
|----------|-------|
| **System** | `sgos-accounting` |
| **Domain** | [accounting.sgl.as](https://accounting.sgl.as) |
| **Status** | Planned |

Accounting system as a single source of truth for all business matters that are financially relevant.

| | |
|---|---|
| **Input** | Financial transactions (Banks, Stripe), API, Users (bank feeds, manual entries) |
| **Output** | API, Exports (VAT, DATEV) |
| **Connections** | Human in the Soup, Docflow, Xhosa, DATEV |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Inventory

| Property | Value |
|----------|-------|
| **System** | `sgos-inventory` |
| **Domain** | [inventory.sgl.as](https://inventory.sgl.as) |
| **Status** | Planned |

Single source of truth for all physical stock movements and quantities. Tracks what's where, reservations, and stock history. References products from Baobab.

| | |
|---|---|
| **Input** | UI (stock movements), API |
| **Output** | UI, API |
| **Connections** | Baobab, Xhosa, Accounting |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Baobab (Product Master)

| Property | Value |
|----------|-------|
| **System** | `sgos-baobab` |
| **Domain** | [baobab.sgl.as](https://baobab.sgl.as) |
| **Status** | Concept |

Product Information Management (PIM) system. Single source of truth for all products (finished goods and raw materials), brands, and marketplace listings.

**Core principle:** Products exist independently of inventory. Baobab defines *what* things are; Inventory tracks *how many* and *where*.

**Features:**
- Product master data (SKUs, names, types, attributes, variants)
- Brand management (logos, guidelines, assets)
- Marketplace listings (external IDs, platform mappings)
- Content management (descriptions, translations, images)
- Categories and tags
- Bill of materials references (for MRP)

| | |
|---|---|
| **Input** | UI, API |
| **Output** | UI, API |
| **Connections** | Inventory, Xhosa, MRP, Ufudu, Website |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### MRP (Manufacturing)

| Property | Value |
|----------|-------|
| **System** | `sgos-mrp` |
| **Domain** | [mrp.sgl.as](https://mrp.sgl.as) |
| **Status** | Planned |

Manufacturing and production with flat-file architecture and lightweight database. Strongly connected with Inventory and Baobab.

Features:
- Bill of materials from Baobab (product structure, dependencies)
- Work orders managed in lightweight DB
- Pushes actual production to Inventory
- Planning and organisational UI: "What do we need to manufacture and when?"
- Tracks production with barcode scanners (serial numbers, etc.)
- Process flows exposed as UI (SOPs, Incoming Goods, Quality Control)

| | |
|---|---|
| **Input** | UI (stock movements), API |
| **Output** | UI, API |
| **Connections** | Baobab, Inventory, Xhosa, Accounting, Human in the Soup |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Ufudu (Fulfillment)

| Property | Value |
|----------|-------|
| **System** | `sgos-ufudu` |
| **Domain** | [ufudu.sgl.as](https://ufudu.sgl.as) |
| **Status** | Planned |

Pick/Pack fulfillment system for warehouses. Mobile SPA with barcode scanning to guide fulfillment operations. Runs on Android devices with connected barcode scanners.

| | |
|---|---|
| **Input** | API (orders) |
| **Output** | API |
| **Connections** | Human in the Soup, Inventory, Xhosa |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Human in the Soup

| Property | Value |
|----------|-------|
| **System** | `sgos-soup` |
| **Domain** | [soup.sgl.as](https://soup.sgl.as) |
| **Status** | Planned |

General shared to-do list where all systems can report when they need a human to provide data or resolve matters.

Example: Accounting's LLM agent needs a new bank feed → creates a todo here.

Also serves as company-wide process and project management overview with Kanban-style UI.

| | |
|---|---|
| **Input** | API (LLMs use it) |
| **Output** | API (callback URLs), UI (task management) |
| **Connections** | All systems |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Anansi (AI Assistant)

| Property | Value |
|----------|-------|
| **System** | `sgos-anansi` |
| **Domain** | [anansi.sgl.as](https://anansi.sgl.as) |
| **Status** | Planned |

Internal general AI assistant connected to all systems. Exposed as chatbot and API. Consumes all important information and stores in vector database for retrieval. Helps internally and with customer support.

All knowledge is scoped and classified from public to internal.

| | |
|---|---|
| **Input** | All systems via API (push or pull, jobs or tool calls) |
| **Output** | Internal Chatbot, External Chat (website), API |
| **Connections** | All systems |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Ikhaya (Knowledge Base)

| Property | Value |
|----------|-------|
| **System** | `sgos-ikhaya` |
| **Domain** | [ikhaya.sgl.as](https://ikhaya.sgl.as) |
| **Status** | Planned |

Internal knowledge base and blog (Docusaurus project). Contains all company knowledge. Embeds Anansi as a chatbot.

| | |
|---|---|
| **Input** | API, Users |
| **Output** | UI, Google Chat (notifications) |
| **Connections** | Anansi |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Directory

| Property | Value |
|----------|-------|
| **System** | `sgos-directory` |
| **Domain** | [directory.sgl.as](https://directory.sgl.as) |
| **Status** | Planned |

A user directory exposed as a simple API so all apps know: Who is who. Central management of users and their attributes. Apps still manage access control and permissions individually.

| | |
|---|---|
| **Input** | UI, Google Workspace Sync |
| **Output** | Private API (for UI), Internal API (for other apps) |
| **Connections** | All modules |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Clock (Time Tracking)

| Property | Value |
|----------|-------|
| **System** | `sgos-clock` |
| **Domain** | [clock.sgl.as](https://clock.sgl.as) |
| **Status** | Concept |

Internal time tracking and attendance system for Sonnenglas employees. Tracks working time, leave, and attendance for compliance, transparency, and payroll.

**Core principle:** Explicitly separate what was planned from what actually happened.

For each user and each scheduled workday, the system generates a **Scheduled_Work** entry in advance. This entry represents both what *should* happen (plan) and what *did* happen (actual). This avoids deriving payroll and compliance data from raw clock events and enables simple queries, deterministic exports, and clean audit trails.

**Features:**
- Clock-in / clock-out
- Leave & vacation scheduling
- Work location enforcement (GPS / IP)
- Holiday awareness (via Nagar IT API)
- Role-based work schedules (RRULE-based)
- Dashboard (compliance & overview)
- Payroll exports (CSV / PDF)
- Notifications (email)
- Mobile-friendly UI
- Optional NFC / terminal-based clock-in

| | |
|---|---|
| **Input** | UI, API |
| **Output** | UI, API |
| **Connections** | Directory (users, roles, companies), Nagar IT API (public holidays) |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

## Infrastructure Systems

### Message Bus

| Property | Value |
|----------|-------|
| **System** | `sgos-bus` |
| **Domain** | [bus.sgl.as](https://bus.sgl.as) |
| **Status** | Planned |

Event bus for async communication between systems. Simple Postgres-backed append-only events table exposed via API. Systems publish events when things happen, other systems subscribe. Reduces polling, enables loose coupling, provides audit trail.

Events follow a shared dictionary/schema.

| | |
|---|---|
| **Input** | API (all systems publish) |
| **Output** | API (poll or webhooks) |
| **Connections** | All systems |

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

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

### Identity (Pocket ID)

| Property | Value |
|----------|-------|
| **System** | `sgos-id` |
| **Domain** | [id.sgl.as](https://id.sgl.as) |
| **Status** | Live |

Self-hosted identity provider using Pocket ID. Provides authentication for users without Google accounts. Supports passkeys/WebAuthn.

| | |
|---|---|
| **Input** | Users (login) |
| **Output** | OIDC Provider |
| **Connections** | Cloudflare Zero Trust, all apps |

---

### Sangoma (Error Analysis)

| Property | Value |
|----------|-------|
| **System** | `sgos-sangoma` |
| **Domain** | [sangoma.sgl.as](https://sangoma.sgl.as) |
| **Status** | Concept |

Automated error analysis and fix proposal system. Monitors GlitchTip for errors, analyzes them with Claude, and proposes fixes as GitHub pull requests or issues.

**Core principle:** Never auto-apply fixes. Maximum action is opening a PR.

**How it works:**
1. Scheduled or manual trigger starts an analysis run
2. Fetches unresolved errors from GlitchTip
3. Clones affected repos and passes error + code to Claude
4. Claude analyzes and proposes fixes with confidence levels
5. High confidence → Create PR; Low confidence → Create issue
6. Notifies via Google Chat

**Features:**
- GlitchTip integration (Sentry-compatible API)
- Claude Code integration (server-side auth)
- GitHub PR/issue creation
- Deduplication (tracks analyzed errors)
- Context memory (rolling summary per app)
- Web UI for run history and findings

| | |
|---|---|
| **Input** | GlitchTip API (errors), GitHub (source code) |
| **Output** | GitHub PRs/issues, Google Chat notifications |
| **Connections** | GlitchTip, GitHub, Claude, Google Chat |

**APIs:**

| Type | URL | Available |
|------|-----|-----------|
| Private | `/api/...` | Yes |
| Internal | `/api/int/v1/...` | Yes |
| Public | — | No |

---

## External Systems

These systems are not part of the SGOS namespace (not internally developed or hosted externally). External systems use the `sonnenglas.net` domain.

### Website

| Property | Value |
|----------|-------|
| **Domain** | [sonnenglas.net](https://sonnenglas.net) |
| **Hosting** | Cloudflare Pages |

Public website and e-commerce shop. Static pages using Astro.js with dynamic islands. Connects to product catalogue, checkout via Stripe. Orders end up in Xhosa.

| | |
|---|---|
| **Input** | Public website |
| **Output** | Orders to Xhosa (via Stripe) |
| **Connections** | Xhosa, Stripe, Anansi |

---

### Partner Portal

| Property | Value |
|----------|-------|
| **Domain** | [partner.sonnenglas.net](https://partner.sonnenglas.net) |

Portal for resellers to login and manage their orders.

| | |
|---|---|
| **Input** | Public website (with login) |
| **Output** | Orders to Xhosa |
| **Connections** | Xhosa |

---

## Architecture Notes

### Identity & Access Control

- All apps behind Tailscale, only expose 80/443 over Cloudflare Tunnel
- Access control via Cloudflare Zero Trust (Google Login, Pocket ID, Service Auth for APIs, app-specific API keys with scopes)
- Service-to-service communication within Tailscale internal network

**User Identity:**
- Google Workspace Login
- Pocket ID ([id.sgl.as](https://id.sgl.as))
- Directory available to all apps via Directory API

### Networking

**Tailscale:**
All servers use Tailscale for internal network with MagicDNS and internal APIs.

| Property | Value |
|----------|-------|
| Tailnet | `tail5b811.ts.net` |

**Cloudflare Tunnel:**
Cloudflare Zero Trust tunnels expose apps while keeping servers isolated.

### Modularity

While all tools are listed separately, they can also be subpages/modules in a single UI layer. The above describes the structural setup, not necessarily the presentation to users. Most systems run on the same server in Docker containers.

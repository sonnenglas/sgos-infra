---
title: API Strategy
sidebar_position: 3
description: API versioning, contracts, and documentation conventions
---

# API Strategy

All SGOS modules communicate through versioned APIs.

## Why API-First? {#agent-native}

SGOS follows **Agent Native Infrastructure**: every operation available to humans must be equally accessible to LLM agents. This means:

- **No UI-only features** — Everything goes through the API first, UI is just one consumer
- **Consistent authentication** — Service accounts for agents, OAuth for humans, same permissions model
- **Structured responses** — JSON that agents can parse and act on without scraping
- **OpenAPI specs** — Machine-readable contracts that agents use to generate tool definitions

This is the foundation for human-LLM collaboration: agents can read orders, create invoices, update inventory, and orchestrate workflows — the same operations humans perform through the UI.

## API Types

Each API type serves a different audience:

| Type | Audience | Stability | Example Consumer |
|------|----------|-----------|------------------|
| **Private** | Own frontend | Unstable, can change anytime | phone.sgl.as web UI |
| **Internal** | Other SGOS apps | Stable, versioned | Accounting calling Inventory |
| **Public** | External consumers | Stable, versioned | Partners, third-party tools |

### Why Three Separate APIs?

A public consumer shouldn't see internal endpoints they can't use. Separate APIs = clear boundaries. Each type has its own documentation so consumers only see what's relevant to them.

## Documentation URL Convention

Each API type has its own folder containing both human-readable docs and machine-readable specs:

```
/api/                        ← Private API (unstable)
├── docs                     ← Swagger UI for humans
├── openapi.json             ← OpenAPI spec for machines
└── ...endpoints

/api/int/v1/                 ← Internal API v1 (stable)
├── docs
├── openapi.json
└── ...endpoints

/api/pub/v1/                 ← Public API v1 (stable)
├── docs
├── openapi.json
└── ...endpoints
```

### URL Reference

| API Type | Base Path | Swagger UI | OpenAPI Spec |
|----------|-----------|------------|--------------|
| Private | `/api/` | `/api/docs` | `/api/openapi.json` |
| Internal v1 | `/api/int/v1/` | `/api/int/v1/docs` | `/api/int/v1/openapi.json` |
| Internal v2 | `/api/int/v2/` | `/api/int/v2/docs` | `/api/int/v2/openapi.json` |
| Public v1 | `/api/pub/v1/` | `/api/pub/v1/docs` | `/api/pub/v1/openapi.json` |

### Rules

1. **Docs and spec together** — If you have `/api/int/v1/docs`, you must have `/api/int/v1/openapi.json`
2. **Versioned APIs only** — Internal and public APIs must be versioned (v1, v2, etc.)
3. **Private is unversioned** — It's for your own frontend, version doesn't matter
4. **Not all apps need all types** — An app may only have private API, or only internal

### FastAPI Implementation

Use FastAPI sub-applications to mount each API type at its correct path:

```python
from fastapi import FastAPI

app = FastAPI(docs_url=None, openapi_url=None)  # Disable root docs

# Private API (for own frontend)
private = FastAPI(
    title="Phone API",
    docs_url="/docs",
    openapi_url="/openapi.json"
)
app.mount("/api", private)

# Internal API v1 (for other SGOS apps)
internal_v1 = FastAPI(
    title="Phone Internal API",
    version="1.0.0",
    docs_url="/docs",
    openapi_url="/openapi.json"
)
app.mount("/api/int/v1", internal_v1)

# Public API v1 (for external consumers) — if needed
public_v1 = FastAPI(
    title="Phone Public API",
    version="1.0.0",
    docs_url="/docs",
    openapi_url="/openapi.json"
)
app.mount("/api/pub/v1", public_v1)
```

Each sub-application generates its own isolated documentation at its mount point.

## OpenAPI as Contract

For versioned APIs (internal and public):

1. Code defines the API (Pydantic schemas in FastAPI)
2. FastAPI generates OpenAPI automatically
3. Export `openapi.json` and commit to git
4. Test against the spec to verify the contract

The committed `openapi.json` is the contract.

## Versioning Policy

| Change | Action |
|--------|--------|
| Add optional field | No version bump |
| Add new endpoint | No version bump |
| Remove field/endpoint | **New version (v2)** |
| Change field type | **New version (v2)** |

Breaking changes require a new version with deprecation period for the old version.

---

## Internal Service Communication

How SGOS apps communicate with each other securely without going through Cloudflare.

### Network Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           Tailscale Network                              │
│                                                                          │
│   Hornbill (100.67.57.25)              Toucan (100.102.199.98)          │
│   ┌────────────────────────┐           ┌────────────────────────┐       │
│   │ sgos-phone       :8003 │           │ sgos-sangoma     :8001 │       │
│   │ sgos-xhosa       :8002 │◀─────────▶│ monitoring             │       │
│   │ sgos-directory   :8001 │ Tailscale │                        │       │
│   │ sgos-docflow     :8004 │  (always) │                        │       │
│   └────────────────────────┘           └────────────────────────┘       │
└──────────────────────────────────────────────────────────────────────────┘
                    │
                    │ (external users only)
                    ▼
            Cloudflare Tunnel
```

All internal communication uses Tailscale IPs, even between apps on the same server. This keeps things simple - one URL pattern everywhere.

### URL Patterns

| Scenario | URL Pattern | Network |
|----------|-------------|---------|
| Internal (any server) | `http://100.x.x.x:8000` | Tailscale |
| External users | `https://<app>.sgl.as` | Cloudflare |

**Why Tailscale for everything (even same-server)?**
- One URL per service - works anywhere, no special cases
- Apps can move between servers without config changes
- WireGuard overhead is negligible (kernel-level, very fast)
- Simpler mental model

**Important:** Internal apps NEVER call each other through Cloudflare (`*.sgl.as`). That would route traffic through the internet unnecessarily.

### Service Registry

Central reference for internal service URLs:

| Service | Tailscale URL | Server |
|---------|---------------|--------|
| Directory | `http://100.67.57.25:8001` | Hornbill |
| Xhosa | `http://100.67.57.25:8002` | Hornbill |
| Phone | `http://100.67.57.25:8003` | Hornbill |
| Docflow | `http://100.67.57.25:8004` | Hornbill |
| Sangoma | `http://100.102.199.98:8001` | Toucan |

*Ports are examples - assign as needed.*

### Configuration Example

Each app configures internal URLs for services it depends on:

```bash
# .env for sgos-phone (on Hornbill)

# All internal services use Tailscale IPs
DIRECTORY_URL=http://100.67.57.25:8001
XHOSA_URL=http://100.67.57.25:8002
SANGOMA_URL=http://100.102.199.98:8001

# Shared secret for internal API auth
INTERNAL_API_TOKEN=${INTERNAL_API_TOKEN}
```

### Internal API Authentication

Two-layer security for internal APIs:

| Layer | Purpose | Protects against |
|-------|---------|------------------|
| **Network** | Only Tailscale/Docker IPs can reach internal APIs | External attackers |
| **Token** | Shared secret in header | Rogue processes on trusted servers |

#### IP Verification

Internal APIs only accept requests from Tailscale IPs (`100.64.0.0/10`).

#### Token Verification

All internal API calls include a shared token:

```
X-Internal-Token: <shared-secret>
```

The token is stored in each app's `.env` (encrypted via SOPS) and rotated periodically.

#### Middleware Implementation

```python
from fastapi import Request, HTTPException
import ipaddress
import os

# Tailscale uses the CGNAT range (100.64.0.0/10)
TAILSCALE_NETWORK = ipaddress.ip_network("100.64.0.0/10")

def get_client_ip(request: Request) -> str:
    """Get real client IP, handling proxies."""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host

async def verify_internal_request(request: Request):
    """Verify request is from internal network with valid token."""
    client_ip = ipaddress.ip_address(get_client_ip(request))

    # Check IP is from Tailscale network
    if client_ip not in TAILSCALE_NETWORK:
        raise HTTPException(status_code=403, detail="Forbidden: Not from Tailscale")

    # Check token
    token = request.headers.get("X-Internal-Token")
    if token != os.environ.get("INTERNAL_API_TOKEN"):
        raise HTTPException(status_code=401, detail="Unauthorized: Invalid token")

# Apply to internal API routes
@internal_v1.middleware("http")
async def internal_auth_middleware(request: Request, call_next):
    await verify_internal_request(request)
    return await call_next(request)
```

#### Making Internal API Calls

```python
import httpx
import os

class InternalClient:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.headers = {
            "X-Internal-Token": os.environ["INTERNAL_API_TOKEN"]
        }

    async def get(self, path: str):
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}{path}",
                headers=self.headers
            )
            response.raise_for_status()
            return response.json()

# Usage
directory = InternalClient(os.environ["DIRECTORY_URL"])
user = await directory.get("/api/int/v1/users/stefan@sonnenglas.net")
```

### Token Management

The `INTERNAL_API_TOKEN` is:
- Generated once, shared across all apps
- Stored encrypted in each app's `.env.sops`
- Rotated by updating all `.env.sops` files and redeploying

To generate a new token:

```bash
openssl rand -base64 32
```

### Summary

| Access Type | Network Path | Auth Method |
|-------------|--------------|-------------|
| User → App | Internet → Cloudflare → Tunnel | Cloudflare Zero Trust |
| App → App | Tailscale (always) | Tailscale IP check + token |

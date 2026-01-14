---
title: API Strategy
sidebar_position: 3
description: API versioning, contracts, and documentation conventions
---

# API Strategy

All SGOS modules communicate through versioned APIs.

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

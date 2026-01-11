---
title: API Strategy
sidebar_position: 2
description: API versioning and contracts
---

# API Strategy

All SGOS modules communicate through versioned APIs.

## API Types

| Type | URL Pattern | Stability |
|------|-------------|-----------|
| Private | `/api/...` | Unstable (own frontend only) |
| Internal | `/api/int/v1/...` | Stable, versioned (other SGOS apps) |
| Public | `/api/pub/v1/...` | Stable, versioned (external consumers) |

## Documentation URLs

Every app exposes docs at predictable URLs:

- `/api/docs` — Private API (Swagger UI)
- `/api/int/v1/docs` — Internal API
- `/api/int/v1/openapi.json` — Internal API spec

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

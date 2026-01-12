---
title: Authentication
sidebar_position: 4
description: How authentication works across services
---

# Authentication

All services are protected by **Cloudflare Zero Trust** which requires authentication before accessing any app. Some apps support **auto-login** via Cloudflare headers, eliminating the need for a separate app login.

## Authentication Methods

| Method | Description |
|--------|-------------|
| **Google Workspace** | Primary IdP via Cloudflare Zero Trust (`@sonnenglas.net`) |
| **PocketID** | Self-hosted OIDC provider for non-Google users (passkey auth) |
| **Cloudflare Headers** | Apps read `Cf-Access-Authenticated-User-Email` for auto-login |
| **App OIDC** | Apps authenticate directly via OIDC (PocketID or Google) |

## Authentication Matrix

| App | Zero Trust | Auto-Login | App Login Required | Notes |
|-----|------------|------------|-------------------|-------|
| **Dashboard** | Google | N/A | No | Static dashboard, no user accounts |
| **Beszel** | Google | Yes | No | Uses `TRUSTED_AUTH_HEADER` |
| **Dozzle** | Google | Yes | No | Uses `forward-proxy` auth provider |
| **SGOS Infra Docs** | Google | N/A | No | Static docs, no user accounts |
| **GlitchTip** | Google | No | Yes (OIDC) | Configure OIDC with PocketID or Google |
| **PocketID** | None | N/A | Yes (passkey) | IS the identity provider |
| **Phone** | None | N/A | No | Public webhook endpoint |

## Authentication Flows

### Flow 1: Zero Trust + Auto-Login (Beszel, Dozzle)

```
User → beszel.sgl.as → Cloudflare Zero Trust → Google Login
                               ↓
                       User authenticated
                               ↓
           Cloudflare adds Cf-Access-Authenticated-User-Email header
                               ↓
                   Beszel reads header → Auto-logged in
```

### Flow 2: Zero Trust + Separate App Login (GlitchTip)

```
User → glitchtip.sgl.as → Cloudflare Zero Trust → Google Login
                               ↓
                       User passes Zero Trust
                               ↓
                   GlitchTip shows its own login
                               ↓
           User logs in via OIDC (PocketID or Google directly)
```

### Flow 3: No Zero Trust (PocketID)

```
User → id.sgl.as → PocketID login page → Passkey authentication
```

## Configuration Details

### Beszel Auto-Login

```yaml
environment:
  - TRUSTED_AUTH_HEADER=Cf-Access-Authenticated-User-Email
```

### Dozzle Auto-Login

```yaml
environment:
  - DOZZLE_AUTH_PROVIDER=forward-proxy
  - DOZZLE_AUTH_HEADER_USER=Cf-Access-Authenticated-User-Email
  - DOZZLE_AUTH_HEADER_EMAIL=Cf-Access-Authenticated-User-Email
  - DOZZLE_AUTH_HEADER_NAME=Cf-Access-Authenticated-User-Email
```

### PocketID (OIDC Provider)

```yaml
environment:
  - APP_URL=https://id.sgl.as
  - TRUST_PROXY=true
  - ENCRYPTION_KEY=<generated-key>
```

## Adding PocketID to Cloudflare Zero Trust

To allow PocketID users to authenticate via Zero Trust:

1. Cloudflare Dashboard → Zero Trust → Settings → Authentication
2. Add new Login Method → OpenID Connect
3. Configure:
   - Name: `PocketID`
   - App ID: (create OIDC client in PocketID)
   - Client Secret: (from PocketID)
   - Auth URL: `https://id.sgl.as/authorize`
   - Token URL: `https://id.sgl.as/api/oidc/token`
   - JWKS URL: `https://id.sgl.as/.well-known/jwks.json`

## GlitchTip OIDC Setup

To configure GlitchTip with PocketID:

1. Create OIDC client in PocketID admin
2. In GlitchTip Django Admin (`/admin/socialaccount/socialapp/`):
   - Provider: OpenID Connect
   - Client ID: (from PocketID)
   - Secret: (from PocketID)
   - Settings: `{"server_url": "https://id.sgl.as"}`

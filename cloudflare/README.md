# Cloudflare Infrastructure

Terraform configuration for Cloudflare resources (sgl.as zone).

## Architecture Overview

### Tunnels

| Tunnel | Server | Services |
|--------|--------|----------|
| **toucan.sgl.as** | Toucan (control) | GlitchTip, SGOS Infra Docs, Dashboard, Beszel, Dozzle, PocketID |
| **hornbill** | Hornbill (app) | Phone |

### Services

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| GlitchTip | glitchtip.sgl.as | 8000 | Error tracking |
| SGOS Infra Docs | sgos-infra.sgl.as | 4200 | Infrastructure documentation |
| Dashboard | dashboard.sgl.as | 3003 | Homepage dashboard |
| Beszel | beszel.sgl.as | 8090 | Server monitoring |
| Dozzle | dozzle.sgl.as | 8888 | Docker log viewer |
| PocketID | id.sgl.as | 3080 | Identity provider (OIDC) |
| Phone | phone.sgl.as | 9000 | Voicemail system |

## Authentication

### Overview

All services are protected by **Cloudflare Zero Trust** which requires authentication before accessing any app. Additionally, some apps support **auto-login** via Cloudflare headers, eliminating the need for a separate app login.

### Authentication Methods

| Method | Description |
|--------|-------------|
| **Google Workspace** | Primary IdP via Cloudflare Zero Trust (`@sonnenglas.net`) |
| **PocketID** | Self-hosted OIDC provider for non-Google users (passkey auth) |
| **Cloudflare Headers** | Apps read `Cf-Access-Authenticated-User-Email` for auto-login |
| **App OIDC** | Apps authenticate directly via OIDC (PocketID or Google) |

### Authentication Matrix

| App | Zero Trust | Auto-Login | App Login Required | Notes |
|-----|------------|------------|-------------------|-------|
| **Dashboard** | Google | N/A | No | Static dashboard, no user accounts |
| **Beszel** | Google | Yes | No | Uses `TRUSTED_AUTH_HEADER` |
| **Dozzle** | Google | Yes | No | Uses `forward-proxy` auth provider |
| **SGOS Infra Docs** | Google | N/A | No | Static docs, no user accounts |
| **GlitchTip** | Google | No | Yes (OIDC) | Configure OIDC with PocketID or Google |
| **PocketID** | None | N/A | Yes (passkey) | IS the identity provider |
| **Phone** | None | N/A | No | Public webhook endpoint |

### Authentication Flows

#### Flow 1: Zero Trust + Auto-Login (Beszel, Dozzle)
```
User → beszel.sgl.as → Cloudflare Zero Trust → Google Login
                                ↓
                        User authenticated
                                ↓
            Cloudflare adds Cf-Access-Authenticated-User-Email header
                                ↓
                    Beszel reads header → Auto-logged in
```

#### Flow 2: Zero Trust + Separate App Login (GlitchTip)
```
User → glitchtip.sgl.as → Cloudflare Zero Trust → Google Login
                                ↓
                        User passes Zero Trust
                                ↓
                    GlitchTip shows its own login
                                ↓
            User logs in via OIDC (PocketID or Google directly)
```

#### Flow 3: No Zero Trust (PocketID)
```
User → id.sgl.as → PocketID login page → Passkey authentication
```

### Configuration Details

#### Beszel Auto-Login
```yaml
environment:
  - TRUSTED_AUTH_HEADER=Cf-Access-Authenticated-User-Email
```

#### Dozzle Auto-Login
```yaml
environment:
  - DOZZLE_AUTH_PROVIDER=forward-proxy
  - DOZZLE_AUTH_HEADER_USER=Cf-Access-Authenticated-User-Email
  - DOZZLE_AUTH_HEADER_EMAIL=Cf-Access-Authenticated-User-Email
  - DOZZLE_AUTH_HEADER_NAME=Cf-Access-Authenticated-User-Email
```

#### PocketID (OIDC Provider)
```yaml
environment:
  - APP_URL=https://id.sgl.as
  - TRUST_PROXY=true
  - ENCRYPTION_KEY=<generated-key>
```

### Adding PocketID to Cloudflare Zero Trust

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

### GlitchTip OIDC Setup

To configure GlitchTip with PocketID:

1. Create OIDC client in PocketID admin
2. In GlitchTip Django Admin (`/admin/socialaccount/socialapp/`):
   - Provider: OpenID Connect
   - Client ID: (from PocketID)
   - Secret: (from PocketID)
   - Settings: `{"server_url": "https://id.sgl.as"}`

## Terraform Setup

### 1. Create API Token

Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens):

1. Create Custom Token
2. Token name: `terraform-sgl-as`
3. Permissions:
   - Account / Cloudflare Tunnel / Edit
   - Account / Access: Apps and Policies / Edit
   - Zone / DNS / Edit
4. Zone Resources: Include → Specific zone → sgl.as
5. Create Token

Reference: [Cloudflare Tunnel Terraform Guide](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/deployment-guides/terraform/)

### 2. Get IDs

**Account ID:** Cloudflare dashboard → any zone → Overview → right sidebar

**Zone ID:** Cloudflare dashboard → sgl.as → Overview → right sidebar

### 3. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Import Existing Resources

Import existing resources so Terraform doesn't recreate them:

```bash
# Import tunnel (get tunnel ID from dashboard or API)
terraform import cloudflare_tunnel.toucan <account-id>/<tunnel-id>

# Import access application
terraform import cloudflare_access_application.glitchtip <zone-id>/<app-id>
```

### 6. Plan and Apply

```bash
# See what would change
terraform plan

# Apply changes
terraform apply
```

## Files

| File | Purpose |
|------|---------|
| versions.tf | Terraform and provider versions |
| variables.tf | Input variable definitions |
| main.tf | Provider configuration |
| tunnel.tf | Cloudflare Tunnel configuration |
| dns.tf | DNS records for all services |
| access.tf | Zero Trust apps and policies |
| terraform.tfvars | Your secrets (gitignored) |

## Server Configuration

### Toucan (/srv/services/monitoring/)

Services managed via docker-compose:
- **Beszel** (hub) - Server metrics dashboard
- **Beszel Agent** - Local metrics collector
- **Dozzle** - Docker log viewer (central, connects to Hornbill agent)
- **Homepage** - Dashboard with links to all services
- **Watchtower** - Auto-updates containers with label `com.centurylinklabs.watchtower.enable=true`
- **PocketID** - OIDC identity provider

### Hornbill (/srv/services/monitoring/)

Services managed via docker-compose:
- **Dozzle Agent** - Sends logs to Toucan Dozzle
- **Beszel Agent** - Sends metrics to Toucan Beszel

### Inter-Server Communication

Servers communicate via Tailscale:
- Toucan: `100.102.199.98`
- Hornbill: `100.67.57.25`

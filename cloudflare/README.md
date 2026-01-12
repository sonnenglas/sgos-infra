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

See [Authentication Documentation](../docs/operations/authentication.md) for details on:
- Authentication methods (Google, PocketID, Cloudflare headers)
- Authentication matrix per app
- Auto-login configuration (Beszel, Dozzle)
- OIDC setup (GlitchTip, PocketID)

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

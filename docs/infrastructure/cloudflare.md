---
title: Cloudflare
sidebar_position: 6
description: Tunnels, DNS, and Zero Trust access via Terraform
---

# Cloudflare

DNS, tunnels, and Zero Trust access are managed via Terraform.

## Location

Configuration lives in `/cloudflare/` in this repository.

## What's Managed

| Resource | Purpose |
|----------|---------|
| Tunnels | toucan.sgl.as, hornbill |
| Tunnel configs | Ingress rules (hostname → service) |
| DNS records | CNAME records pointing to tunnels |
| Access Applications | Zero Trust protected apps |
| Access Policies | Who can access what |

## Workflow

```bash
cd cloudflare
terraform plan    # Review changes
terraform apply   # Apply changes
```

## Adding a New Service

1. Add ingress rule to the tunnel config (tunnel.tf)
2. Add DNS CNAME record (dns.tf)
3. Optionally add Zero Trust protection (access.tf)
4. Run `terraform apply`

## Secrets

`terraform.tfvars` contains the API token and is gitignored. The token needs:
- Zone / DNS / Edit
- Account / Zero Trust / Edit
- Account / Cloudflare Tunnel / Edit

## State

Terraform state is stored locally in `terraform.tfstate`. This file is gitignored but should be backed up.

## cloudflared Daemon

The `cloudflared` daemon runs on both servers as a systemd service with **token-based configuration**:

```bash
# On both Toucan and Hornbill
ExecStart=/usr/bin/cloudflared --no-autoupdate tunnel run --token <token>
```

### How It Works

1. cloudflared authenticates to Cloudflare using the embedded token
2. Cloudflare returns the tunnel configuration (ingress rules)
3. cloudflared routes traffic according to those rules

### Implications

- **Ingress rules are managed remotely** (via Terraform's `cloudflare_zero_trust_tunnel_cloudflared_config`)
- **No local config files** exist on the servers
- **Changes require `terraform apply`** - there's no quick local switching

This is why apps use an nginx sidecar for maintenance mode instead of switching cloudflared config directly.

### Checking Status

```bash
# On any server
systemctl status cloudflared
journalctl -u cloudflared -f
```

## Zero Trust Access Policies

All services are protected by Cloudflare Access. Authentication options:

| Method | Use Case |
|--------|----------|
| Google Workspace | Primary login for team members |
| PocketID (OIDC) | Users without Google accounts |
| Service Tokens | API and automation access |

### Adding a Protected App

```hcl
# In access.tf
resource "cloudflare_zero_trust_access_application" "my_app" {
  zone_id          = var.zone_id
  name             = "My App"
  domain           = "myapp.sgl.as"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_zero_trust_access_policy" "my_app" {
  application_id = cloudflare_zero_trust_access_application.my_app.id
  zone_id        = var.zone_id
  name           = "Allow Google"
  decision       = "allow"
  precedence     = 1

  include {
    gsuite {
      identity_provider_id = var.google_idp_id
    }
  }
}
```

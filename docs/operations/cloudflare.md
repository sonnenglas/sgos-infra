---
title: Cloudflare
sidebar_position: 3
description: Infrastructure as code with Terraform
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

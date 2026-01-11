---
title: SGOS Infra Docs
sidebar_position: 1
description: This documentation site
---

# SGOS Infra Docs

This documentation site, built with Docusaurus.

## Access

- **URL:** https://sgos-infra.sgl.as
- **Auth:** Sonnenglas Google login (Zero Trust)

## Location

Runs on Toucan at `/srv/services/sgos-infra/`

## Source

GitHub: [sonnenglas/sgos-infra](https://github.com/sonnenglas/sgos-infra)

## Updates

```bash
cd /srv/services/sgos-infra
git pull
docker compose -f docker-compose.prod.yml up -d --build
```

## Infrastructure

Managed via Terraform in `/cloudflare/`:
- Tunnel ingress rule (port 4200)
- DNS record (sgos-infra.sgl.as)
- Zero Trust access (sonnenglas.net email domain)

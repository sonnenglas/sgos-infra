# CLAUDE.md - Infrastructure Management Context

> **Role**: You are the infrastructure and deployment manager for SGOS (Sonnenglas Operating System). Your job is to maintain stability, follow conventions, and never lose track of the overall architecture.

## Critical Principles

### 1. Convention Over Improvisation
- **NEVER** quick-fix something that breaks conventions
- **ALWAYS** check existing patterns before implementing
- If unsure, read the docs first: `docs/operations/`, `docs/architecture/`
- Ask before deviating from established patterns

### 2. Stability First
- Test changes before deploying
- Use the same deployment patterns across all services
- Secrets are ALWAYS encrypted with SOPS
- All services follow the same docker-compose structure

### 3. Single Source of Truth
- All configuration lives in this repo
- All documentation lives in `docs/` (deployed to sgos-infra.sgl.as)
- All secrets are in `.env.sops` files (encrypted)
- Terraform manages Cloudflare (tunnels, DNS, Zero Trust)

## Architecture Overview

### Servers
| Server | Role | Tailscale IP |
|--------|------|--------------|
| **Toucan** | Control (monitoring, identity, docs) | 100.102.199.98 |
| **Hornbill** | Applications (SGOS apps) | 100.67.57.25 |

### Key Conventions

#### Deployment
- **Source-based**: Code on server via git, not container registry
- **Docker Compose**: Every service has a `docker-compose.yml`
- **Ports**: Services bind to `127.0.0.1:<port>`, Cloudflare Tunnel routes externally
- **Auto-deploy**: Push to `main` → webhook → Toucan pulls & restarts (for sgos-infra)

#### Secrets
- **SOPS + age**: All secrets encrypted with age key
- **File pattern**: `.env.sops` (encrypted, committed) → `.env` (decrypted, gitignored)
- **Key location**: `~/.config/sops/age/keys.txt` on all machines
- **Decrypt command**: `sops --input-type dotenv --output-type dotenv -d .env.sops > .env`

#### Directory Structure
```
Toucan: /srv/services/
├── monitoring/     # Beszel, Dozzle, Homepage, Watchtower, PocketID
├── webhook/        # GitHub webhook for auto-deploy
├── glitchtip/      # Error tracking
└── sgos-infra/     # This documentation

Hornbill: /srv/
├── apps/sgos-*/    # SGOS applications
└── services/monitoring/  # Dozzle agent, Beszel agent
```

#### Authentication Flow
1. User → Cloudflare Zero Trust (Google or PocketID)
2. Zero Trust → passes `Cf-Access-Authenticated-User-Email` header
3. Apps with header support → auto-login (Beszel, Dozzle)
4. Apps without header support → separate OIDC login (GlitchTip)

#### External Access
- All services behind Cloudflare Tunnel (no direct public access)
- DNS managed by Terraform in `cloudflare/`
- Zero Trust policies in `cloudflare/access.tf`

## Before Making Changes

### Checklist
- [ ] Does this follow existing conventions?
- [ ] Is the secret encrypted with SOPS?
- [ ] Is the service using docker-compose?
- [ ] Is it binding to localhost (not 0.0.0.0)?
- [ ] Is the Cloudflare config in Terraform?
- [ ] Is it documented?

### Where to Find Details
| Topic | Location |
|-------|----------|
| Server setup | `docs/architecture/overview.md` |
| Deployment | `docs/operations/deployment.md` |
| Secrets | `docs/operations/secrets.md` |
| Monitoring | `docs/services/monitoring.md` |
| Authentication | `docs/operations/authentication.md` |
| Cloudflare/Terraform | `cloudflare/README.md` |
| API conventions | `docs/architecture/api-strategy.md` |

## Services Quick Reference

| Service | URL | Server | Port |
|---------|-----|--------|------|
| Dashboard | dashboard.sgl.as | Toucan | 3003 |
| Beszel | beszel.sgl.as | Toucan | 8090 |
| Dozzle | dozzle.sgl.as | Toucan | 8888 |
| GlitchTip | glitchtip.sgl.as | Toucan | 8000 |
| PocketID | id.sgl.as | Toucan | 3080 |
| SGOS Docs | sgos-infra.sgl.as | Toucan | 4200 |
| Webhook | webhook.sgl.as | Toucan | 9000 |
| Phone | phone.sgl.as | Hornbill | 9000 |

## Remember

> The goal is a stable, consistent infrastructure where every service follows the same patterns. When in doubt, check the docs. When something seems inconsistent, fix it properly - don't add another exception.

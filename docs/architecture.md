# Architecture Overview

## Network Topology

```
                    ┌─────────────────┐
                    │   Cloudflare    │
                    │   Zero Trust    │
                    └────────┬────────┘
                             │ Tunnels
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ dokploy-toucan│   │ glitchtip.    │   │ (future apps) │
│    .sgl.as    │   │   sgl.as      │   │               │
└───────┬───────┘   └───────┬───────┘   └───────────────┘
        │                   │
        └─────────┬─────────┘
                  │
                  ▼
        ┌─────────────────┐         ┌─────────────────┐
        │     TOUCAN      │◄───────►│    HORNBILL     │
        │  (Ctrl Server)  │Tailscale│  (App Server)   │
        │  152.53.160.251 │ ~1.3ms  │ 159.195.68.119  │
        └─────────────────┘         └─────────────────┘
```

## Server Roles

### Toucan (Control Server)

Manages and monitors all infrastructure:

- **Dokploy** - Deployment platform for all apps
- **Grafana/Loki/Alloy** - Centralized logging
- **GlitchTip** - Error tracking
- Future: Backups coordination, alerting

### Hornbill (Application Server)

Runs the actual business applications:

- Xhosa (Sales/Orders)
- Beanstock (Inventory)
- Docflow (Documents)
- Other Sonnenglas apps

## Security Model

### Network Access

1. **Public Internet** → Cloudflare Tunnel → Specific services only
2. **Internal** → Tailscale mesh → Full access between servers
3. **SSH** → Tailscale only (public SSH disabled)

### Firewall Rules (UFW)

```
Default: deny incoming, allow outgoing

Allow:
- Anything on tailscale0 interface
- Port 443/tcp (for Cloudflare Tunnel)
```

### Authentication

- **Server access:** Tailscale SSH (no passwords)
- **Dokploy:** Username/password
- **Grafana:** Username/password (admin/admin initially)
- **GlitchTip:** Email/password registration
- **Future apps:** Cloudflare Zero Trust + Google Workspace

## Data Flow

### Logs

```
Apps on Hornbill
      │
      ▼ (Alloy collects Docker logs)
      │
      ▼ (Ships to Toucan via Tailscale)
      │
      ▼
Loki on Toucan (stores logs)
      │
      ▼
Grafana (view/query logs)
```

### Errors

```
Apps (any server)
      │
      ▼ (Sentry SDK)
      │
      ▼
GlitchTip on Toucan
      │
      ▼
Email notifications / Dashboard
```

### Deployments

```
GitHub (code)
      │
      ▼
Dokploy on Toucan (orchestrates)
      │
      ├──► Toucan (services like GlitchTip)
      │
      └──► Hornbill (business apps)
```

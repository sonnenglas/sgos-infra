# Architecture Overview

## Database Strategy

**Decision:** Every app gets its own Postgres instance.

**Why:**

1. **Isolation** - One app's database crash doesn't affect others
2. **Version flexibility** - App A can use Postgres 16, App B can use Postgres 18
3. **Portability** - Each app is a self-contained unit, easy to move between servers
4. **Simpler backups** - Backup/restore per app, not "extract one app from shared DB"
5. **Security** - No risk of one app accessing another's data
6. **Resource overhead is minimal** - ~100-200MB RAM per idle instance, negligible with 32GB available

**Trade-off accepted:** Cannot do direct SQL joins across apps. Solved via analytics layer (see below).

## Analytics Strategy

For company-wide analytics and cross-app queries:

**Approach:** Read-only analytics database (data warehouse pattern)

```
┌─────────┐  ┌─────────┐  ┌─────────┐
│  Xhosa  │  │Beanstock│  │ Docflow │  ... (all apps)
│Postgres │  │Postgres │  │Postgres │
└────┬────┘  └────┬────┘  └────┬────┘
     │            │            │
     └────────────┼────────────┘
                  │ nightly sync (cron)
                  ▼
          ┌──────────────┐
          │  Analytics   │
          │  Postgres    │  (read-only replica)
          └──────┬───────┘
                 │
                 ▼
          ┌──────────────┐
          │   Metabase   │  (dashboards, queries)
          └──────────────┘
```

**Options (choose later based on needs):**

| Option | Complexity | Best For |
|--------|------------|----------|
| Metabase connecting to each DB | Low | Simple dashboards |
| Nightly sync to analytics DB | Medium | Cross-app queries, historical data |
| Real-time replication (Postgres logical replication) | High | Up-to-the-minute analytics |

**For now:** Not implemented. Add when analytics needs arise.

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

# Toucan Server Setup

Control server for Sonnenglas infrastructure running Dokploy.

## Server Details

| Property | Value |
|----------|-------|
| Hostname | toucan |
| Public IP | 152.53.160.251 |
| Tailscale IP | 100.102.199.98 |
| DNS | toucan.sgl.as |
| Provider | Netcup |
| OS | Ubuntu 24.04.3 LTS |
| Kernel | 6.8.0-90-generic |
| CPU | 8 vCPU |
| RAM | 16 GB |
| Swap | 8 GB |
| Disk | 1 TB NVMe |

---

## Users

| Username | UID | Groups | Purpose |
|----------|-----|--------|---------|
| stefan | 1000 | sudo, docker | Primary admin (passwordless sudo) |
| root | 0 | - | Disabled for SSH login |

---

## Security Configuration

### SSH Access
- **Public SSH:** DISABLED (ListenAddress Tailscale only)
- **Tailscale SSH:** ENABLED
- **Password auth:** DISABLED
- **Root login:** prohibit-password

Access via: `ssh stefan@toucan` or `ssh stefan@100.102.199.98`

### Firewall (UFW)
```
Status: active

Default: deny (incoming), allow (outgoing)

To                         Action      From
--                         ------      ----
Anywhere on tailscale0     ALLOW IN    Anywhere
22                         ALLOW IN    172.16.0.0/12
443/tcp                    ALLOW IN    Anywhere
```

### Fail2Ban
- Installed and enabled
- Default jails active (SSH protection)

### Automatic Updates
- unattended-upgrades: ENABLED

---

## Dokploy Installation

| Component | Details |
|-----------|---------|
| Version | Latest (auto-updating) |
| Data Directory | /etc/dokploy/ |
| Domain | dokploy-toucan.sgl.as |
| Access | HTTPS via Cloudflare Tunnel |

### Services (Docker Swarm)

| Service | Image | Replicas |
|---------|-------|----------|
| dokploy | dokploy/dokploy:latest | 1/1 |
| dokploy-postgres | postgres:16 | 1/1 |
| dokploy-redis | redis:7 | 1/1 |

### Environment Variables

| Variable | Value |
|----------|-------|
| ADVERTISE_ADDR | 172.17.0.1 |
| DOKPLOY_DOMAIN | dokploy-toucan.sgl.as |

---

## Cloudflare Tunnel

| Property | Value |
|----------|-------|
| Service | cloudflared (systemd) |
| Status | Active |
| Route | dokploy-toucan.sgl.as -> localhost:3000 |

The tunnel provides external HTTPS access without exposing ports directly.

---

## Directory Structure

```
/srv/
├── apps/                    # Reserved for Dokploy
├── data/                    # Persistent data volumes
│   ├── postgres/
│   ├── redis/
│   ├── files/
│   ├── grafana/             # Grafana dashboards, users
│   └── loki/                # Log storage
├── backups/                 # Backup staging and logs
│   ├── staging/             # Collected from all servers
│   ├── status.json          # Backup status per app
│   └── backup.log           # Backup run log
├── config/                  # App configs
│   └── monitoring/          # Grafana/Loki/Alloy stack
│       ├── docker-compose.yml
│       ├── loki.yml
│       └── alloy.config
└── services/
    └── backups/             # Backup orchestrator
        ├── .env             # R2 credentials, restic password
        └── backup-orchestrator.sh

/etc/dokploy/                # Dokploy data
├── applications/
├── logs/
├── monitoring/
├── schedules/
├── ssh/
├── traefik/
└── volume-backups/
```

Owner: stefan:stefan

---

## Monitoring Stack (Grafana + Loki + Alloy)

Runs outside Dokploy for independence. Centralized logging for both Toucan and Hornbill.

| Component | Image | Port | Purpose |
|-----------|-------|------|---------|
| Grafana | grafana/grafana:11.4.0 | 3001 | Log visualization UI |
| Loki | grafana/loki:3.3.2 | 3100 | Log storage (accepts remote) |
| Alloy | grafana/alloy:v1.5.1 | - | Log collector |

### Architecture

```
Hornbill (100.67.57.25)          Toucan (100.102.199.98)
┌─────────────────────┐          ┌─────────────────────┐
│ Docker containers   │          │ Docker containers   │
│        │            │          │        │            │
│        ▼            │          │        ▼            │
│      Alloy          │────────▶ │      Alloy ───▶ Loki│
│  (server=hornbill)  │  :3100   │  (server=toucan)  │ │
└─────────────────────┘          │                    ▼ │
                                 │               Grafana│
                                 └─────────────────────┘
                                           │
                                 Cloudflare Tunnel
                                           ▼
                                   grafana.sgl.as
```

### Access

- **Public:** https://grafana.sgl.as (Google SSO via Cloudflare Access)
- **Tailscale:** `http://toucan:3001`
- **Default credentials:** admin / admin (change on first login)

### Log Retention

- 30 days (configured in loki.yml)

### Containers Being Logged

All Docker containers are automatically discovered and logged by Alloy:
- **Toucan:** Dokploy services, monitoring stack, GlitchTip
- **Hornbill:** Phone app, proxy, any future apps

Logs are labeled with `server=toucan` or `server=hornbill` for filtering.

### Example Queries

```logql
# All logs from Hornbill
{server="hornbill"}

# Phone app logs
{server="hornbill", container="phone"}

# GlitchTip errors
{server="toucan", container=~"glitchtip.*"} |= "error"
```

### Management

```bash
# Toucan stack
cd /srv/config/monitoring && docker compose up -d
cd /srv/config/monitoring && docker compose down
cd /srv/config/monitoring && docker compose restart

# Hornbill Alloy
cd /srv/services/alloy && docker compose up -d
cd /srv/services/alloy && docker compose restart

# View logs
docker logs grafana
docker logs loki
docker logs alloy
```

---

## Docker

| Component | Version |
|-----------|---------|
| Docker Engine | 29.1.3 |
| Docker Compose | 5.0.1 |
| Swarm Mode | Active (Manager) |

Stefan is in the `docker` group (can run docker without sudo).

---

## SSH Access to Hornbill

Toucan can SSH to Hornbill for deployments and backups.

| Property | Value |
|----------|-------|
| Key | `/home/stefan/.ssh/deploy_hornbill` |
| Target | `stefan@100.67.57.25` (Hornbill via Tailscale) |
| Used by | Webhook deploy scripts, backup orchestrator |

```bash
# Test connection
ssh -i ~/.ssh/deploy_hornbill stefan@100.67.57.25 "hostname"
```

---

## Network

### Interfaces
| Interface | Purpose |
|-----------|---------|
| eth0 | Public network (152.53.160.251) |
| tailscale0 | Tailscale mesh (100.102.199.98) |
| docker0 | Docker bridge network |
| docker_gwbridge | Docker Swarm gateway |

### Tailscale Peers
| Host | Tailscale IP | Role |
|------|--------------|------|
| toucan | 100.102.199.98 | Ctrl Server (Dokploy) |
| hornbill | 100.67.57.25 | App Server |
| Latency | ~1.27ms | Same datacenter |

---

## Changelog

| Date | Action |
|------|--------|
| 2026-01-08 | Cleaned up old containers (Portainer, Glances, etc.) |
| 2026-01-08 | Configured UFW firewall |
| 2026-01-08 | Installed and enabled Fail2Ban |
| 2026-01-08 | Increased swap from 4GB to 8GB |
| 2026-01-08 | Made stefan passwordless sudo |
| 2026-01-08 | Installed Dokploy |
| 2026-01-08 | Configured Cloudflare Tunnel route (dokploy-toucan.sgl.as) |
| 2026-01-09 | Fixed "Invalid origin" error with DOKPLOY_DOMAIN env var |
| 2026-01-09 | Installed monitoring stack (Grafana + Loki + Alloy) |
| 2026-01-12 | Exposed Loki for remote log collection (port 3100) |
| 2026-01-12 | Installed Alloy on Hornbill shipping logs to Toucan |
| 2026-01-12 | Added Grafana to Cloudflare tunnel (grafana.sgl.as) |

---

## Next Steps

1. ~~Add Hornbill as remote server in Dokploy~~
2. Configure Traefik for app routing
3. ~~Deploy first application~~
4. ~~Set up error tracking (GlitchTip)~~
5. ~~Configure backup jobs~~ ✅ Backup orchestrator at `/srv/services/backups/`
6. ~~Install Alloy on Hornbill to ship logs to Toucan~~ ✅ Centralized logging complete
7. Set up uptime monitoring (Uptime Kuma)

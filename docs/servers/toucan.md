# Toucan Server

Control server for Sonnenglas infrastructure.

## Specifications

| Property | Value |
|----------|-------|
| Hostname | toucan |
| Provider | Netcup |
| Location | Vienna, Austria |
| Public IP | 152.53.160.251 |
| Tailscale IP | 100.102.199.98 |
| DNS | toucan.sgl.as |
| OS | Ubuntu 24.04.3 LTS |
| CPU | 8 vCPU |
| RAM | 16 GB |
| Swap | 8 GB |
| Disk | 1 TB NVMe |

## Access

```bash
# Via Tailscale (preferred)
ssh stefan@toucan

# Via Tailscale IP
ssh stefan@100.102.199.98
```

Public SSH is disabled.

## Services Running

| Service | Port | Purpose |
|---------|------|---------|
| Dokploy | 3000 | Deployment platform |
| Grafana | 3001 | Log visualization |
| Loki | 3100 (internal) | Log storage |
| Alloy | - | Log collection |
| GlitchTip | 8000 | Error tracking |
| Cloudflared | - | Cloudflare Tunnel |

## Directory Structure

```
/srv/
├── config/
│   └── monitoring/
│       ├── docker-compose.yml
│       ├── loki.yml
│       └── alloy.config
├── data/
│   ├── grafana/
│   ├── loki/
│   ├── postgres/
│   └── redis/
└── backups/

/etc/dokploy/          # Dokploy data
```

## Installed Software

- Docker CE 29.1.3
- Docker Compose 5.0.1
- Tailscale 1.92.5
- UFW (firewall)
- Fail2Ban
- unattended-upgrades

## Maintenance

### View logs

```bash
# Monitoring stack
docker logs grafana
docker logs loki
docker logs alloy

# Dokploy services
docker service logs dokploy
```

### Restart monitoring stack

```bash
cd /srv/config/monitoring
docker compose restart
```

### Update monitoring stack

```bash
cd /srv/config/monitoring
docker compose pull
docker compose up -d
```

## Setup History

1. Initial OS installation (Ubuntu 24.04.3)
2. Created user `stefan` with sudo access
3. Installed Tailscale, enabled Tailscale SSH
4. Configured UFW firewall (deny all except tailscale0 and 443)
5. Installed Fail2Ban
6. Enabled unattended-upgrades
7. Created 8GB swap
8. Installed Docker
9. Installed Dokploy
10. Configured Cloudflare Tunnel
11. Installed monitoring stack (Grafana/Loki/Alloy)
12. Deployed GlitchTip via Dokploy

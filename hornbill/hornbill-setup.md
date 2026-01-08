# Hornbill Server Setup

Base configuration for the Sonnenglas App Server before Dokploy/Coolify installation.

## Server Details

| Property | Value |
|----------|-------|
| Hostname | hornbill |
| Public IP | 159.195.68.119 |
| Tailscale IP | 100.67.57.25 |
| DNS | hornbill.sgl.as |
| Provider | Netcup |
| Datacenter | Nuremberg (ordered) / Vienna (detected via IP) |
| OS | Ubuntu 24.04.3 LTS |
| Kernel | 6.8.0-90-generic |
| CPU | 12 vCPU (AMD EPYC 9645) |
| RAM | 32 GB |
| Swap | 8 GB |
| Disk | 1 TB NVMe |

---

## Benchmark Results (2026-01-08)

| Component | Result |
|-----------|--------|
| Geekbench 6 Single | 2244 |
| Geekbench 6 Multi | 14267 |
| Disk 4k R/W | 667 MB/s (166k IOPS) |
| Disk 64k R/W | 4.2 GB/s |
| Network (Amsterdam) | 2.7 Gbps / 10ms |
| Full benchmark | https://browser.geekbench.com/v6/cpu/15992569 |

---

## Users

| Username | UID | Groups | Purpose |
|----------|-----|--------|---------|
| stefan | 1000 | sudo, docker | Primary admin |
| root | 0 | - | Disabled for SSH login |

---

## Security Configuration

### SSH Access
- **Public SSH:** DISABLED (ListenAddress 100.67.57.25 only)
- **Tailscale SSH:** ENABLED
- **Password auth:** DISABLED
- **Root login:** prohibit-password (key only, but no keys configured)

Access via: `ssh stefan@hornbill` or `ssh stefan@100.67.57.25`

### Firewall (UFW)
```
Status: active

Default: deny (incoming), allow (outgoing)

To                         Action      From
--                         ------      ----
Anywhere on tailscale0     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
```

### Fail2Ban
- Installed and enabled
- Default jails active (SSH protection)

### Automatic Updates
- unattended-upgrades: ENABLED
- APT::Periodic::Update-Package-Lists "1"
- APT::Periodic::Unattended-Upgrade "1"

---

## System Configuration

### Timezone
```
Europe/Berlin (CET, +0100)
NTP: active, synchronized
```

### Swap
```
/swapfile  8GB  active
```

### Installed Packages
- curl, wget, git
- htop, ncdu
- vim, jq
- zip, unzip
- fail2ban
- unattended-upgrades
- Docker CE 29.1.3
- Docker Compose 5.0.1
- Tailscale 1.92.5

---

## Directory Structure

```
/srv/
├── apps/                    # Reserved for Dokploy/Coolify
├── data/                    # Persistent data volumes
│   ├── postgres/
│   ├── redis/
│   └── files/               # Uploaded files, documents
├── backups/                 # Local backup staging
│   └── daily/
└── config/                  # App configs (if needed outside containers)
```

Owner: stefan:stefan

---

## Docker

| Component | Version |
|-----------|---------|
| Docker Engine | 29.1.3 |
| Docker Compose | 5.0.1 |
| containerd | 2.2.1 |
| runc | 1.3.4 |

Stefan is in the `docker` group (can run docker without sudo).

---

## Network

### Interfaces
| Interface | Purpose |
|-----------|---------|
| eth0 | Public network (159.195.68.119) |
| tailscale0 | Tailscale mesh (100.67.57.25) |
| docker0 | Docker bridge network |

### Tailscale Peers (same network)
| Host | Tailscale IP | Role |
|------|--------------|------|
| hornbill | 100.67.57.25 | App Server |
| toucan | 100.102.199.98 | Ctrl Server |
| Latency | ~1.27ms | Same datacenter |

---

## What's NOT Configured (Dokploy/Coolify handles these)

| Component | Reason |
|-----------|--------|
| Reverse Proxy (Traefik/Caddy) | Managed by Dokploy/Coolify |
| SSL Certificates (Let's Encrypt) | Managed by Dokploy/Coolify |
| Container orchestration | Managed by Dokploy/Coolify |
| App deployments | Managed by Dokploy/Coolify |
| Database containers | Managed by Dokploy/Coolify |
| Monitoring dashboards | Ctrl server (Toucan) |
| Log aggregation | Ctrl server (Toucan) |
| Cloudflare Tunnel | To be configured with Dokploy/Coolify |

---

## Changelog

| Date | Action |
|------|--------|
| 2026-01-08 | Initial OS: Ubuntu 24.04.3 LTS |
| 2026-01-08 | Installed Tailscale 1.92.5, enabled Tailscale SSH |
| 2026-01-08 | System updates applied |
| 2026-01-08 | Created user: stefan (sudo, docker) |
| 2026-01-08 | Created 8GB swap file |
| 2026-01-08 | Set timezone: Europe/Berlin |
| 2026-01-08 | Installed basic packages |
| 2026-01-08 | Locked SSH to Tailscale only |
| 2026-01-08 | Configured UFW (deny all, allow tailscale0, allow 443) |
| 2026-01-08 | Installed and enabled Fail2Ban |
| 2026-01-08 | Enabled unattended-upgrades |
| 2026-01-08 | Created /srv directory structure |
| 2026-01-08 | Installed Docker CE 29.1.3 + Compose 5.0.1 |

---

## Next Steps

1. Install Dokploy or Coolify
2. Configure Cloudflare Tunnel for public access
3. Deploy first application
4. Set up backups to Ctrl server (Toucan)

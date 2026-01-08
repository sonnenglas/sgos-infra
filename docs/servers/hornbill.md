# Hornbill Server

Application server for Sonnenglas business apps.

## Specifications

| Property | Value |
|----------|-------|
| Hostname | hornbill |
| Provider | Netcup |
| Location | Vienna, Austria (detected) / Nuremberg (ordered) |
| Public IP | 159.195.68.119 |
| Tailscale IP | 100.67.57.25 |
| DNS | hornbill.sgl.as |
| OS | Ubuntu 24.04.3 LTS |
| CPU | 12 vCPU (AMD EPYC 9645) |
| RAM | 32 GB |
| Swap | 8 GB |
| Disk | 1 TB NVMe |

## Benchmark Results

| Test | Result |
|------|--------|
| Geekbench 6 Single | 2244 |
| Geekbench 6 Multi | 14267 |
| Disk 4k R/W | 667 MB/s (166k IOPS) |
| Disk 64k R/W | 4.2 GB/s |
| Network (Amsterdam) | 2.7 Gbps / 10ms |

Full benchmark: https://browser.geekbench.com/v6/cpu/15992569

## Access

```bash
# Via Tailscale (preferred)
ssh stefan@hornbill

# Via Tailscale IP
ssh stefan@100.67.57.25
```

Public SSH is disabled.

## Directory Structure

```
/srv/
├── apps/           # Dokploy deployments
├── data/
│   ├── postgres/
│   ├── redis/
│   └── files/
├── backups/
└── config/
```

## Installed Software

- Docker CE 29.1.3
- Docker Compose 5.0.1
- Tailscale 1.92.5
- UFW (firewall)
- Fail2Ban
- unattended-upgrades

## Future Apps

This server will run:

- Xhosa (Sales/Orders)
- Beanstock (Inventory)
- Ufudu (Fulfillment)
- Docflow (Documents)
- Precounting (Accounting)
- MRP (Manufacturing)
- And others...

## Pending Setup

1. Add as remote server in Dokploy
2. Install Alloy to ship logs to Toucan
3. Deploy first application

## Setup History

1. Initial OS installation (Ubuntu 24.04.3)
2. Created user `stefan` with sudo access
3. Installed Tailscale, enabled Tailscale SSH
4. Configured UFW firewall
5. Installed Fail2Ban
6. Enabled unattended-upgrades
7. Created 8GB swap
8. Installed Docker
9. Created /srv directory structure

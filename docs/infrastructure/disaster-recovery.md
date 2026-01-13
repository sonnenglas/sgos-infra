---
title: Disaster Recovery
sidebar_position: 7
description: Recovery procedures for infrastructure failures
---

# Disaster Recovery

Procedures for recovering from server failures, data loss, and infrastructure emergencies.

## Recovery Scenarios

### Scenario 1: Hornbill Server Failure (App Server)

**Impact:** All SGOS apps offline (phone, future apps)

**Recovery Steps:**

1. **Provision new server** (Netcup or equivalent)
   - Ubuntu 24.04 LTS
   - Minimum: 8 vCPU, 16GB RAM, 500GB NVMe

2. **Base setup** (follow `hornbill/hornbill-setup.md`):
   ```bash
   # Install Tailscale
   curl -fsSL https://tailscale.com/install.sh | sh
   tailscale up

   # Install Docker
   curl -fsSL https://get.docker.com | sh
   usermod -aG docker stefan

   # Install packages
   apt install -y curl wget git htop ncdu vim jq zip unzip fail2ban
   ```

3. **Restore SSH keys:**
   ```bash
   # Copy deploy key from Toucan
   scp stefan@toucan:/home/stefan/.ssh/deploy_hornbill ~/.ssh/
   ```

4. **Create directory structure:**
   ```bash
   mkdir -p /srv/{infra,services,apps}
   chown -R stefan:stefan /srv
   ```

5. **Restore apps from backup:**
   ```bash
   # On Toucan, get latest backup
   restic -r s3:s3.eu-central-1.amazonaws.com/sgos-backups snapshots

   # Restore to new Hornbill
   restic -r s3:... restore latest --target /tmp/restore
   scp -r /tmp/restore/sgos-phone stefan@new-hornbill:/srv/apps/
   ```

6. **Clone app repositories:**
   ```bash
   cd /srv/apps/sgos-phone
   git clone https://github.com/sonnenglas/sgos-phone.git src
   ```

7. **Decrypt secrets and start:**
   ```bash
   cd /srv/apps/sgos-phone
   sops -d src/.env.sops > .env
   docker compose up -d
   ```

8. **Update Cloudflare tunnel:**
   - Update Tailscale IP in tunnel config if changed
   - Run `terraform apply` in `/cloudflare`

9. **Update Toucan references:**
   - Update IP in `/srv/services/status/status.py`
   - Update IP in backup orchestrator if hardcoded

**RTO:** ~2 hours | **RPO:** Up to 24 hours (last backup)

---

### Scenario 2: Toucan Server Failure (Control Server)

**Impact:** Monitoring, backups, webhooks, status page offline. Apps on Hornbill continue running.

**Recovery Steps:**

1. **Provision new server** (Netcup or equivalent)
   - Ubuntu 24.04 LTS
   - Minimum: 4 vCPU, 8GB RAM, 200GB NVMe

2. **Base setup** (follow `toucan/toucan-setup.md`):
   ```bash
   # Install Tailscale, Docker (same as Hornbill)
   # Install additional packages
   apt install -y rsync restic python3
   ```

3. **Restore monitoring stack:**
   ```bash
   mkdir -p /srv/services/monitoring
   # Configs are in git - clone and start
   cd /srv/services/monitoring
   docker compose up -d
   ```

4. **Restore backup orchestrator:**
   ```bash
   mkdir -p /srv/services/backups
   # Copy scripts from infra repo
   ```

5. **Restore cron jobs:**
   ```bash
   crontab -e
   # Add:
   # 0 3 * * * /srv/services/backups/backup-orchestrator.sh >> /srv/backups/cron.log 2>&1
   # * * * * * /usr/bin/python3 /srv/services/status/status.py > /dev/null 2>&1
   ```

6. **Generate new SSH key for Hornbill access:**
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/deploy_hornbill -N ""
   ssh-copy-id -i ~/.ssh/deploy_hornbill stefan@hornbill
   ```

7. **Restore Cloudflare tunnel:**
   ```bash
   # Get tunnel token from Cloudflare dashboard
   docker run -d cloudflare/cloudflared tunnel --token <TOKEN>
   ```

8. **Restore R2 credentials:**
   - Get from 1Password
   - Configure in `/srv/services/backups/.env`

**RTO:** ~3 hours | **RPO:** N/A (Toucan doesn't store app data)

---

### Scenario 3: Data Corruption (Single App)

**Recovery Steps:**

1. **Stop the affected app:**
   ```bash
   ssh stefan@hornbill
   cd /srv/apps/sgos-<app>
   docker compose down
   ```

2. **List available backups:**
   ```bash
   ssh stefan@toucan
   restic -r s3:s3.eu-central-1.amazonaws.com/sgos-backups snapshots
   ```

3. **Restore specific snapshot:**
   ```bash
   restic restore <SNAPSHOT_ID> --target /tmp/restore --include "sgos-<app>"
   ```

4. **Replace corrupted data:**
   ```bash
   scp -r /tmp/restore/sgos-<app>/backup/* stefan@hornbill:/srv/apps/sgos-<app>/backup/
   ```

5. **Restore database:**
   ```bash
   ssh stefan@hornbill
   cd /srv/apps/sgos-<app>
   docker compose up -d db
   docker exec -i sgos-<app>-db psql -U postgres < backup/database.sql
   docker compose up -d
   ```

---

### Scenario 4: SOPS Key Loss

**Impact:** Cannot decrypt any secrets

**Recovery:**

1. **Retrieve from 1Password:**
   - Location: SGOS vault → "age secret key"
   - Copy to `~/.config/sops/age/keys.txt`

2. **If 1Password unavailable:**
   - Secrets must be regenerated
   - Update all `.env.sops` files with new key
   - Rotate all API keys, database passwords

**Prevention:** Ensure key is backed up in 1Password and tested quarterly.

---

### Scenario 5: Cloudflare Account Compromise

**Immediate Actions:**

1. Revoke all API tokens in Cloudflare dashboard
2. Rotate tunnel secrets
3. Review Zero Trust access logs
4. Generate new Terraform API token
5. Re-run `terraform apply`

---

## Infrastructure Components Not Backed Up

These must be recreated from documentation:

| Component | Recovery Source |
|-----------|-----------------|
| Server OS config | `hornbill-setup.md`, `toucan-setup.md` |
| Docker networks | Created automatically by compose |
| Cloudflare tunnels | Terraform + dashboard |
| SSH keys | Generate new, update authorized_keys |
| Cron jobs | Documented in server setup files |
| Grafana dashboards | Recreate manually (or export/backup separately) |

## Emergency Contacts

| Service | Recovery Method |
|---------|-----------------|
| Netcup (hosting) | support@netcup.de |
| Cloudflare | Dashboard + support |
| GitHub | Repository access via account |
| 1Password | Account recovery |

## Testing Disaster Recovery

Quarterly tests recommended:

1. **Backup restore test:** Restore random app to `/tmp`, verify data
2. **Key recovery test:** Decrypt a secret using 1Password backup
3. **Documentation test:** Follow setup docs on a test VM

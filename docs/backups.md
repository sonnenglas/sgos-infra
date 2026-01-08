# Backup Strategy

## Storage

**Provider:** Cloudflare R2
- 10GB free tier
- S3-compatible API
- No egress fees

**Bucket:** `sonnenglas-backups`

**Structure:**
```
sonnenglas-backups/
├── glitchtip/       # GlitchTip Postgres dumps
├── dokploy/         # Dokploy config backups
├── xhosa/           # (future)
├── beanstock/       # (future)
└── ...
```

## What Gets Backed Up

### GlitchTip

| What | Method | Schedule | Retention |
|------|--------|----------|-----------|
| Postgres database | Dokploy backup | Daily midnight | 30 backups |

Contains: errors, users, projects, settings

### Dokploy

| What | Method | Schedule | Retention |
|------|--------|----------|-----------|
| Internal Postgres | Dokploy self-backup | Configure in Settings | - |

Contains: all project configs, domains, environment variables

### Monitoring Stack

| What | Method | Notes |
|------|--------|-------|
| Config files | Git repo | `/srv/config/monitoring/` copied to local |
| Grafana dashboards | In /srv/data/grafana | Consider backing up if custom dashboards |
| Loki data | Not backed up | Logs are ephemeral (30 day retention) |

### Infrastructure Config

| What | Method |
|------|--------|
| All documentation | Git repo (this repo) |
| Compose files | Git repo |
| Server setup docs | Git repo |

## Cloudflare R2 Setup

### Create Bucket

1. Cloudflare Dashboard → R2
2. Create bucket: `sonnenglas-backups`
3. Location: EU

### Create API Token

1. R2 → Manage R2 API Tokens
2. Create API Token
3. Name: `dokploy-backups`
4. Permissions: Object Read & Write
5. Bucket: `sonnenglas-backups`

Save:
- Access Key ID
- Secret Access Key
- Endpoint URL

### Configure in Dokploy

1. Settings → S3 Destinations
2. Add destination with R2 credentials
3. Use for backup jobs

## Backup Configuration in Dokploy

### For Database Services

1. Go to Compose/Application → Backups tab
2. Create backup:
   - Database Type: PostgreSQL
   - Destination: Cloudflare R2
   - Service: (select postgres container)
   - Database: (database name)
   - Database User: (username)
   - Prefix: `servicename/`
   - Schedule: Daily
   - Keep latest: 30

## Restore Procedures

### GlitchTip Postgres

1. Download backup from R2
2. Stop GlitchTip web/worker
3. Restore:
   ```bash
   docker exec -i glitchtip-postgres psql -U glitchtip glitchtip < backup.sql
   ```
4. Start web/worker

### Dokploy Config

Restore via Dokploy Settings → Server → Backups

### From Git Repo

```bash
git clone <repo-url>
scp -r toucan/monitoring/* stefan@toucan:/srv/config/monitoring/
ssh stefan@toucan "cd /srv/config/monitoring && docker compose up -d"
```

## Manual Backup Commands

### Postgres Dump

```bash
docker exec glitchtip-postgres pg_dump -U glitchtip glitchtip > backup.sql
```

### Copy to Local

```bash
scp stefan@toucan:/path/to/backup.sql ./
```

## Verification

Periodically test restores:

1. Spin up a test Postgres container
2. Restore a backup
3. Verify data integrity
4. Document the test date

## Not Backed Up (Intentionally)

- **Redis data** - Just cache, regenerates
- **Loki logs** - Ephemeral by design (30 day retention)
- **Docker images** - Pulled from registries

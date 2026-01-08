# GlitchTip

Open-source error tracking (Sentry-compatible).

## Access

- **URL:** https://glitchtip.sgl.as
- **Access:** Cloudflare Tunnel (public with login)
- **Internal:** http://toucan:8000

## Why GlitchTip Over Sentry?

| Aspect | Sentry (self-hosted) | GlitchTip |
|--------|---------------------|-----------|
| RAM | 16GB+ minimum | 1-2GB |
| Services | 20+ containers | 4 containers |
| Complexity | High | Low |
| Features | Full (performance, replay) | Core error tracking |
| SDK | Sentry SDK | Sentry SDK (compatible) |

GlitchTip has everything needed for error tracking without the resource overhead.

## Components

| Service | Image | Purpose |
|---------|-------|---------|
| web | glitchtip/glitchtip | Web UI and API |
| worker | glitchtip/glitchtip | Background jobs (Celery) |
| postgres | postgres:18 | Data storage |
| redis | redis:7 | Caching and queues |
| migrate | glitchtip/glitchtip | Database migrations (runs once) |

## Deployed Via

Dokploy as a Compose project.

Config: `toucan/glitchtip-compose.yml`

## Configuration

### Environment Variables

| Variable | Value |
|----------|-------|
| DATABASE_URL | postgres://glitchtip:glitchtip@postgres:5432/glitchtip |
| SECRET_KEY | (generated, in compose file) |
| GLITCHTIP_DOMAIN | https://glitchtip.sgl.as |
| EMAIL_URL | consolemail:// (logs emails to console) |
| REDIS_URL | redis://redis:6379/0 |

### Networking

All services must be on the same Docker network (`glitchtip`) for service discovery to work.

## Usage

### Creating a Project

1. Log in to GlitchTip
2. Create an Organization (first time only)
3. Create a Project for each app
4. Copy the DSN

### Integrating with Apps

GlitchTip uses the Sentry SDK:

**Laravel:**
```bash
composer require sentry/sentry-laravel
```

```env
SENTRY_LARAVEL_DSN=https://key@glitchtip.sgl.as/1
```

**Node.js:**
```bash
npm install @sentry/node
```

```javascript
Sentry.init({ dsn: "https://key@glitchtip.sgl.as/1" });
```

**Python:**
```bash
pip install sentry-sdk
```

```python
sentry_sdk.init(dsn="https://key@glitchtip.sgl.as/1")
```

### Migrating from Bugsnag

1. Remove Bugsnag package
2. Install Sentry SDK
3. Configure DSN to point to GlitchTip
4. Same error tracking, no subscription cost

## Backup

GlitchTip's data is in Postgres. Backed up via Dokploy:

- **Schedule:** Daily at midnight
- **Retention:** 30 backups
- **Destination:** Cloudflare R2 (`sonnenglas-backups/glitchtip/`)

## Troubleshooting

### 500 Server Error

Usually Redis connection issue. Check:
```bash
docker logs glitchtip-app-xxx-web-1
```

If "redis connection error", ensure all services are on the same network.

### Check Service Status

```bash
docker ps | grep glitchtip
```

### View Logs

In Dokploy: GlitchTip compose → Logs tab

Or via CLI:
```bash
docker logs glitchtip-app-xxx-web-1
docker logs glitchtip-app-xxx-worker-1
```

### Postgres Upgrade Issue

If upgrading Postgres versions (e.g., 16→18), you must either:
1. Delete the volume and start fresh
2. Run pg_upgrade migration

For fresh installs, just delete the volume:
```bash
docker volume rm glitchtip-app-xxx_glitchtip-postgres
```

Then redeploy.

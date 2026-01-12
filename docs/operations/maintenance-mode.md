---
title: Maintenance Mode
sidebar_position: 4
description: Graceful maintenance pages during deployments
---

# Maintenance Mode

During deployments, apps display a maintenance page instead of 502 errors.

## How It Works

Each app uses a **Caddy reverse proxy** that sits between Cloudflare Tunnel and the application:

```
Cloudflare Tunnel → Caddy (port 4200) → App (internal)
```

Caddy checks for a flag file:
- **Flag exists:** Serve maintenance page (auto-refreshes every 10 seconds)
- **Flag absent:** Proxy to the application

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  cloudflared (fetches config from Cloudflare)           │
│       │                                                 │
│       ▼ routes to localhost:4200                        │
│  ┌─────────────────┐                                    │
│  │  Caddy          │                                    │
│  │                 │                                    │
│  │  maintenance.flag exists?                            │
│  │    yes → serve index.html                            │
│  │    no  → reverse_proxy to app                        │
│  └─────────────────┘                                    │
│       │                                                 │
│       ▼                                                 │
│  ┌─────────────────┐                                    │
│  │  Application    │                                    │
│  └─────────────────┘                                    │
└─────────────────────────────────────────────────────────┘
```

## Why Caddy?

Our cloudflared instances use **token-based remote configuration** (managed by Terraform). This means we can't quickly switch ports locally—changes would require `terraform apply`.

The Caddy sidecar approach:
- Works with current cloudflared setup (no migration needed)
- Simple flag-file switching (instant)
- Minimal overhead (~15MB RAM per app)
- No Terraform/Cloudflare API calls during deployment

## Deployment Flow

1. **Enter maintenance:** `touch maintenance-mode/maintenance.flag`
2. **Caddy detects flag:** Serves maintenance page to all visitors
3. **Rebuild app:** Container rebuilds (users see maintenance page)
4. **Exit maintenance:** `rm maintenance-mode/maintenance.flag`
5. **Caddy resumes proxying:** Traffic flows to the updated app

## Manual Maintenance Mode

### Enter Maintenance

```bash
# On the server
touch /srv/services/<app>/maintenance-mode/maintenance.flag
```

### Exit Maintenance

```bash
rm /srv/services/<app>/maintenance-mode/maintenance.flag
```

### Example: SGOS Docs

```bash
# Enter maintenance
touch /srv/services/sgos-infra/maintenance-mode/maintenance.flag

# Exit maintenance
rm /srv/services/sgos-infra/maintenance-mode/maintenance.flag
```

## Adding Maintenance Mode to a New App

### 1. Create maintenance-mode directory

Copy the `maintenance-mode/` folder from sgos-infra or create:

```
maintenance-mode/
└── index.html    # Maintenance page (auto-refresh enabled)
```

### 2. Create Caddyfile

```caddyfile
:PORT {
    @maintenance file /srv/maintenance-mode/maintenance.flag
    handle @maintenance {
        root * /srv/maintenance-mode
        rewrite * /index.html
        file_server
    }
    handle {
        reverse_proxy app:INTERNAL_PORT
    }
}
```

### 3. Update docker-compose.yml

```yaml
services:
  caddy:
    image: caddy:2-alpine
    ports:
      - "127.0.0.1:EXTERNAL_PORT:EXTERNAL_PORT"
    volumes:
      - ./maintenance-mode:/srv/maintenance-mode:ro
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
    depends_on:
      - app
    restart: unless-stopped

  app:
    # ... existing config, remove port mapping ...
```

### 4. Update deploy script

Add flag touch/remove around the rebuild step:

```bash
touch /path/to/maintenance-mode/maintenance.flag
# ... rebuild app ...
rm /path/to/maintenance-mode/maintenance.flag
```

## Customizing the Maintenance Page

Edit `maintenance-mode/index.html`. The default page includes:
- Animated spinner
- "Deploying new version" message
- Auto-refresh every 10 seconds
- Dark mode support
- SGOS branding

## Troubleshooting

### Page stuck on maintenance

Check if the flag file was removed:
```bash
ls -la /srv/services/<app>/maintenance-mode/
```

Remove it manually if needed:
```bash
rm /srv/services/<app>/maintenance-mode/maintenance.flag
```

### Caddy not detecting flag changes

Caddy checks the flag on each request—no reload needed. If issues persist:
```bash
docker compose restart caddy
```

### 502 still showing

Ensure Caddy is running and the port mapping is correct:
```bash
docker compose ps
curl -I http://localhost:4200
```

---
title: Maintenance Mode
sidebar_position: 4
description: Graceful maintenance pages during deployments
---

# Maintenance Mode

During deployments, apps display a maintenance page instead of 502 errors.

## How It Works

Each app uses an **nginx reverse proxy** that sits between Cloudflare Tunnel and the application:

```
Cloudflare Tunnel → nginx (port 4200) → App (internal)
```

nginx checks for a flag file on every request:
- **Flag exists:** Serve maintenance page (auto-refreshes every 10 seconds)
- **Flag absent:** Proxy to the application

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  cloudflared (fetches config from Cloudflare)           │
│       │                                                 │
│       ▼ routes to localhost:4200                        │
│  ┌─────────────────┐                                    │
│  │  nginx          │                                    │
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

## Why nginx?

Our cloudflared instances use **token-based remote configuration** (managed by Terraform). This means we can't quickly switch ports locally—changes would require `terraform apply`.

The nginx sidecar approach:
- Works with current cloudflared setup (no migration needed)
- Simple flag-file switching via `if (-f file)` directive
- Minimal overhead (~10MB RAM per app)
- No Terraform/Cloudflare API calls during deployment

## Deployment Flow

1. **Enter maintenance:** `touch maintenance-mode/maintenance.flag`
2. **nginx detects flag:** Serves maintenance page to all visitors
3. **Rebuild app:** Container rebuilds (users see maintenance page)
4. **Exit maintenance:** `rm maintenance-mode/maintenance.flag`
5. **nginx resumes proxying:** Traffic flows to the updated app

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
├── index.html    # Maintenance page (auto-refresh enabled)
└── nginx.conf    # nginx configuration
```

### 2. Create nginx.conf

```nginx
server {
    listen PORT;
    server_name _;

    set $maintenance 0;
    if (-f /srv/maintenance-mode/maintenance.flag) {
        set $maintenance 1;
    }

    location / {
        if ($maintenance = 1) {
            root /srv/maintenance-mode;
            rewrite ^(.*)$ /index.html break;
        }

        proxy_pass http://app:INTERNAL_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
```

### 3. Update docker-compose.yml

```yaml
services:
  proxy:
    image: nginx:alpine
    ports:
      - "127.0.0.1:EXTERNAL_PORT:EXTERNAL_PORT"
    volumes:
      - ./maintenance-mode:/srv/maintenance-mode:ro
      - ./maintenance-mode/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - app
    restart: unless-stopped

  app:
    # ... existing config, remove external port mapping ...
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

### nginx not detecting flag changes

nginx checks the flag on each request—no reload needed. If issues persist:
```bash
docker compose restart proxy
```

### 502 still showing

Ensure the proxy is running and the port mapping is correct:
```bash
docker compose ps
curl -I http://localhost:4200
```

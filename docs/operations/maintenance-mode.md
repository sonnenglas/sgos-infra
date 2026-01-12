---
title: Maintenance Mode
sidebar_position: 4
description: Graceful maintenance pages during deployments
---

# Maintenance Mode

During deployments, apps display a maintenance page instead of 502 errors.

## How It Works

A **single nginx reverse proxy per server** sits between Cloudflare Tunnel and all apps:

```
Cloudflare Tunnel → sgos-proxy (nginx) → App
                         ↓
                   checks flag file
                   exists? → maintenance.html
                   no? → forward to app
```

That's it. Apps don't need any maintenance-mode code.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  SERVER (Toucan or Hornbill)                                │
│                                                             │
│  cloudflared                                                │
│      │                                                      │
│      ▼                                                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  sgos-proxy (one nginx for ALL apps)                  │  │
│  │                                                       │  │
│  │  Port 4200 → if docs.flag exists → maintenance.html  │  │
│  │              else → proxy to sgos-infra-docs:3000    │  │
│  │                                                       │  │
│  │  Port 9000 → if phone.flag exists → maintenance.html │  │
│  │              else → proxy to sgos-phone-app:8000     │  │
│  └───────────────────────────────────────────────────────┘  │
│      │                    │                                 │
│      ▼                    ▼                                 │
│  ┌────────┐          ┌─────────┐                           │
│  │  Docs  │          │  Phone  │  (apps have NO nginx)     │
│  └────────┘          └─────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

## App Requirements

Apps only need to join the `sgos` Docker network:

```yaml
services:
  myapp:
    build: .
    container_name: sgos-myapp
    # NO port binding to host - proxy handles it
    networks:
      - sgos

networks:
  sgos:
    external: true
```

**That's the only requirement.** No nginx config, no maintenance-mode directory, nothing else.

## Server Directory Structure

```
/srv/proxy/<server>/
├── docker-compose.yml    # Single nginx container
├── nginx.conf            # All app routes
├── maintenance.html      # Shared maintenance page
└── flags/                # Per-app flags (runtime only)
    ├── docs.flag
    └── phone.flag
```

Configuration is managed in the infra repo at `proxy/toucan/` and `proxy/hornbill/`.

## Deployment Flow

1. **Deploy script touches flag:** `/srv/proxy/<server>/flags/<app>.flag`
2. **nginx serves maintenance page** (cached 2s, so up to 2s delay)
3. **App rebuilds** (users see maintenance page)
4. **Deploy script removes flag**
5. **nginx resumes proxying** (again, up to 2s delay)

## Manual Maintenance Mode

### Single App

```bash
# Enter maintenance
touch /srv/proxy/toucan/flags/docs.flag

# Exit maintenance
rm /srv/proxy/toucan/flags/docs.flag
```

### Global (All Apps)

```bash
# Enter maintenance for ALL apps on server
touch /srv/proxy/toucan/flags/global.flag

# Exit maintenance
rm /srv/proxy/toucan/flags/global.flag
```

## Adding a New App

1. **Add server block** to `/srv/proxy/<server>/nginx.conf`:
   ```nginx
   server {
       listen <PORT>;
       resolver 127.0.0.11 valid=10s;
       set $upstream sgos-<app>:<internal-port>;

       error_page 503 @maintenance;
       location @maintenance {
           root /srv;
           try_files /maintenance.html =503;
       }

       location / {
           if (-f /srv/flags/global.flag) { return 503; }
           if (-f /srv/flags/<app>.flag) { return 503; }
           proxy_pass http://$upstream;
           proxy_http_version 1.1;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

2. **Add port** to `/srv/proxy/<server>/docker-compose.yml`:
   ```yaml
   ports:
     - "127.0.0.1:<PORT>:<PORT>"
   ```

3. **Reload nginx:**
   ```bash
   docker exec sgos-proxy nginx -s reload
   ```

4. **Update deploy script** to touch/remove flag at `/srv/proxy/<server>/flags/<app>.flag`

## Troubleshooting

### Stuck on maintenance page

Check if flag exists:
```bash
ls -la /srv/proxy/toucan/flags/
```

Remove manually:
```bash
rm /srv/proxy/toucan/flags/docs.flag
```

### 502 Bad Gateway after container restart

nginx caches DNS for 10 seconds. Either wait, or reload nginx:
```bash
docker exec sgos-proxy nginx -s reload
```

### App not reachable through proxy

Verify app is on the `sgos` network:
```bash
docker inspect <container> --format '{{json .NetworkSettings.Networks}}' | jq 'keys'
```

Connect if missing:
```bash
docker network connect sgos <container>
```

# Dokploy

Self-hosted deployment platform (alternative to Vercel/Netlify/Heroku).

## Access

- **URL:** https://dokploy-toucan.sgl.as
- **Access:** Cloudflare Tunnel (public with login)
- **Internal:** http://toucan:3000

## What It Does

- Deploys Docker containers and compose stacks
- Manages domains and SSL certificates (via Traefik)
- Provides deployment logs and history
- Supports multiple servers (manager + workers)
- Handles environment variables and secrets

## Architecture

Dokploy runs on Docker Swarm with three services:

| Service | Image | Purpose |
|---------|-------|---------|
| dokploy | dokploy/dokploy | Web UI and API |
| dokploy-postgres | postgres:16 | Configuration storage |
| dokploy-redis | redis:7 | Caching |

## Configuration

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| ADVERTISE_ADDR | 172.17.0.1 | Docker network address |
| DOKPLOY_DOMAIN | dokploy-toucan.sgl.as | Allowed origin for CORS |

### Data Location

```
/etc/dokploy/
├── applications/    # Deployed app data
├── logs/
├── monitoring/
├── schedules/
├── ssh/            # SSH keys for remote servers
├── traefik/        # Reverse proxy config
└── volume-backups/
```

## Cloudflare Tunnel Setup

The "Invalid origin" error required setting `DOKPLOY_DOMAIN`:

```bash
docker service update --env-add 'DOKPLOY_DOMAIN=dokploy-toucan.sgl.as' dokploy
```

## Deploying Apps

### Compose Project

1. Create Project
2. Add Compose service
3. Paste docker-compose.yml (use "Raw" source)
4. Deploy
5. Add domain if needed
6. Redeploy to apply domain

### From GitHub

1. Create Project
2. Add Application service
3. Connect GitHub repo
4. Configure build settings
5. Deploy

## Adding Remote Server (Hornbill)

1. Go to Servers in Dokploy
2. Click Add Server
3. Enter Tailscale IP: 100.67.57.25
4. Dokploy will install agent on remote server

## Backup

Dokploy's configuration is stored in its Postgres database. Back it up via:

Settings → Server → Backups

## Troubleshooting

### Check service status

```bash
docker service ls
docker service logs dokploy
```

### Restart Dokploy

```bash
docker service update --force dokploy
```

### View Traefik config

```bash
cat /etc/dokploy/traefik/traefik.yml
```

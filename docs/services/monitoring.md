---
title: Monitoring
sidebar_position: 1
description: Server metrics and Docker logs
---

# Monitoring

Server monitoring with Beszel and centralized Docker logs with Dozzle.

## Services

| Service | URL | Purpose |
|---------|-----|---------|
| Dashboard | https://dashboard.sgl.as | Homepage with links to all services |
| Beszel | https://beszel.sgl.as | Server metrics (CPU, memory, disk, network) |
| Dozzle | https://dozzle.sgl.as | Real-time Docker container logs |

## Architecture

### Beszel

- **Hub** runs on Toucan (port 8090)
- **Agents** run on both Toucan and Hornbill (port 45876)
- Agents send metrics to hub via Tailscale

### Dozzle

- **Central instance** runs on Toucan (port 8888)
- **Remote agent** runs on Hornbill (port 7007)
- Shows logs from both servers in a single UI

## Location

All monitoring services run on Toucan at `/srv/services/monitoring/`

## Authentication

Both Beszel and Dozzle support auto-login via Cloudflare Zero Trust headers:

- User authenticates with Google via Cloudflare Zero Trust
- Cloudflare passes `Cf-Access-Authenticated-User-Email` header
- Apps read header and auto-login the user

### Configuration

**Beszel:**
```yaml
environment:
  - TRUSTED_AUTH_HEADER=Cf-Access-Authenticated-User-Email
```

**Dozzle:**
```yaml
environment:
  - DOZZLE_AUTH_PROVIDER=forward-proxy
  - DOZZLE_AUTH_HEADER_USER=Cf-Access-Authenticated-User-Email
  - DOZZLE_AUTH_HEADER_EMAIL=Cf-Access-Authenticated-User-Email
  - DOZZLE_AUTH_HEADER_NAME=Cf-Access-Authenticated-User-Email
```

## Auto-Updates

Watchtower automatically updates monitoring containers daily at 4 AM.

Containers must have the label `com.centurylinklabs.watchtower.enable=true` to be updated.

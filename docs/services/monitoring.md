# Monitoring Stack

Centralized logging with Grafana, Loki, and Alloy.

## Access

- **Grafana URL:** http://toucan:3001
- **Access:** Tailscale only
- **Default login:** admin / admin (change on first login)

## Components

| Component | Image | Purpose |
|-----------|-------|---------|
| Grafana | grafana/grafana:11.4.0 | Web UI for viewing logs |
| Loki | grafana/loki:3.3.2 | Log storage and indexing |
| Alloy | grafana/alloy:v1.5.1 | Log collector (replaces Promtail) |

## Why Outside Dokploy?

The monitoring stack runs independently of Dokploy because:

1. It should monitor Dokploy itself
2. If Dokploy fails, you still have visibility
3. Infrastructure services ≠ application deployments

## How It Works

```
Docker containers (any server)
         │
         ▼
    Alloy (collector)
         │ reads Docker logs via socket
         ▼
    Loki (storage)
         │ stores and indexes logs
         ▼
    Grafana (UI)
         │ queries Loki
         ▼
    You (view logs)
```

## Configuration Files

Location: `/srv/config/monitoring/`

### docker-compose.yml

Defines the three services with proper networking and volumes.

### loki.yml

```yaml
# Key settings
auth_enabled: false
schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      schema: v13
limits_config:
  retention_period: 30d    # Keep logs for 30 days
```

### alloy.config

Uses River configuration format to:
- Discover Docker containers automatically
- Extract labels (container name, service, project)
- Ship logs to Loki

## Log Retention

- **Duration:** 30 days
- **Storage:** /srv/data/loki/

## Querying Logs

### In Grafana

1. Go to Explore (compass icon)
2. Select "Loki" data source
3. Use LogQL queries:

```logql
# All logs from a container
{container="dokploy"}

# Filter by content
{container="glitchtip-web"} |= "error"

# Multiple containers
{container=~"glitchtip.*"}
```

### Common Queries

```logql
# GlitchTip errors
{container=~"glitchtip.*"} |= "error" | json

# Dokploy deployment logs
{swarm_service="dokploy"}

# All logs in last hour
{container=~".+"}
```

## Management

### Start/Stop/Restart

```bash
cd /srv/config/monitoring
docker compose up -d      # Start
docker compose down       # Stop
docker compose restart    # Restart
```

### Update Images

```bash
cd /srv/config/monitoring
docker compose pull
docker compose up -d
```

### View Container Logs

```bash
docker logs grafana
docker logs loki
docker logs alloy
```

### Check Loki Health

```bash
docker exec loki wget -qO- http://localhost:3100/ready
```

## Adding Hornbill Logs

To collect logs from Hornbill:

1. Install Alloy on Hornbill
2. Configure it to ship logs to Loki on Toucan via Tailscale
3. Logs will appear in Grafana with `host="hornbill"` label

Config for Hornbill's Alloy:
```
loki.write "default" {
  endpoint {
    url = "http://100.102.199.98:3100/loki/api/v1/push"
  }
}
```

(Requires exposing Loki port 3100 on Toucan's Tailscale interface)

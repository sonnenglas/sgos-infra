---
title: Monitoring
sidebar_position: 1
description: Centralized logging
---

# Monitoring

Centralized logging with Grafana, Loki, and Alloy.

## Access

- **Grafana:** http://toucan:3001 (Tailscale only)
- **Default login:** admin / admin

## Location

Runs on Toucan at `/srv/monitoring/`

## How It Works

Alloy collects Docker container logs and ships them to Loki. Grafana queries Loki for visualization.

All servers run Alloy to ship logs to Toucan.

## Log Retention

30 days.

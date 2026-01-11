---
title: GlitchTip
sidebar_position: 2
description: Error tracking
---

# GlitchTip

Self-hosted error tracking, compatible with Sentry SDKs.

## Access

- **URL:** https://glitchtip.sgl.as
- **Internal:** http://toucan:8000

## Location

Runs on Toucan at `/srv/services/glitchtip/`

## Integration

Apps use the standard Sentry SDK, configured with a GlitchTip DSN. Create a project in the GlitchTip web UI to get the DSN.

## Backups

Database is backed up daily via Toucan's backup orchestration.

---
title: Logging Standard
sidebar_position: 4
description: Structured JSON logging for SGOS applications
---

# Logging Standard

All SGOS applications log to stdout. Logs are automatically collected by Alloy, stored in Loki (30 days), and queryable via Grafana.

## Flow

```
App (stdout) → Docker → Alloy → Loki → Grafana
```

Apps just log to stdout. Infrastructure handles the rest.

## Minimum Setup

**None.** Any output to stdout/stderr is automatically collected.

```python
print("Hello")  # Works
logger.info("Hello")  # Works
```

Query in Grafana: `{container="sgos-myapp-app"}`

## Recommended Setup

Use structured JSON for queryable fields:

```python
logger.info("Order created", extra={"order_id": 123, "user_id": "stefan@sonnenglas.net"})
# Output: {"ts":"...","level":"info","msg":"Order created","order_id":123,"user_id":"stefan@sonnenglas.net"}
```

Query in Grafana: `{container="sgos-xhosa-app"} | json | order_id=123`

## Log Format

All logs must be single-line JSON objects:

```json
{"ts":"2026-01-15T12:34:56.789Z","level":"info","msg":"Order created","order_id":123}
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `ts` | string | ISO 8601 timestamp with Z suffix |
| `level` | string | `debug`, `info`, `warn`, `error` |
| `msg` | string | Human-readable message |

### Recommended Fields

| Field | Type | Description |
|-------|------|-------------|
| `request_id` | string | Unique request ID for tracing |
| `user_id` | string | Email of authenticated user |
| `duration_ms` | number | Request/operation duration |

:::note App identification is automatic
You don't need an `app` field. Alloy labels all logs with `container="sgos-<app>-app"` automatically. Query with `{container="sgos-xhosa-app"}`.
:::

### Optional Fields

Add any context relevant to the log entry:

```json
{"ts":"...","level":"info","msg":"Payment processed","order_id":123,"amount":49.95,"currency":"EUR"}
```

## Log Levels

| Level | When to use |
|-------|-------------|
| `debug` | Detailed debugging (disabled in production) |
| `info` | Normal operations (request handled, job completed) |
| `warn` | Recoverable issues (retry succeeded, deprecated usage) |
| `error` | Failures requiring attention (unhandled exception, external service down) |

## FastAPI Implementation

### Basic Setup

```python
# app/logging.py
import json
import logging
import sys
from datetime import datetime, timezone

class JSONFormatter(logging.Formatter):
    """Format logs as single-line JSON."""

    def format(self, record: logging.LogRecord) -> str:
        log = {
            "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z",
            "level": record.levelname.lower(),
            "msg": record.getMessage(),
        }

        # Add exception info
        if record.exc_info:
            log["error"] = self.formatException(record.exc_info)

        # Add extra fields (request_id, user_id, order_id, etc.)
        for key, value in record.__dict__.items():
            if key not in ("name", "msg", "args", "created", "filename",
                          "funcName", "levelname", "levelno", "lineno",
                          "module", "msecs", "pathname", "process",
                          "processName", "relativeCreated", "stack_info",
                          "exc_info", "exc_text", "thread", "threadName",
                          "taskName", "message"):
                log[key] = value

        return json.dumps(log)


def setup_logging(level: str = "INFO"):
    """Configure JSON logging to stdout."""
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JSONFormatter())

    # Configure root logger
    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(getattr(logging, level.upper()))

    # Quiet noisy libraries
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
```

### Usage in FastAPI

```python
# app/main.py
from fastapi import FastAPI, Request
from app.logging import setup_logging
import logging
import uuid

setup_logging()
logger = logging.getLogger(__name__)

app = FastAPI()

@app.middleware("http")
async def logging_middleware(request: Request, call_next):
    request_id = str(uuid.uuid4())[:8]

    # Add request_id to all logs in this request
    logger.info("Request started",
                extra={"request_id": request_id, "path": request.url.path})

    response = await call_next(request)

    logger.info("Request completed",
                extra={"request_id": request_id, "status": response.status_code})

    return response

@app.get("/orders/{order_id}")
async def get_order(order_id: int):
    logger.info("Fetching order", extra={"order_id": order_id})
    # ...
```

### Output

```json
{"ts":"2026-01-15T12:34:56.789Z","level":"info","msg":"Request started","request_id":"a1b2c3d4","path":"/orders/123"}
{"ts":"2026-01-15T12:34:56.812Z","level":"info","msg":"Fetching order","order_id":123}
{"ts":"2026-01-15T12:34:56.845Z","level":"info","msg":"Request completed","request_id":"a1b2c3d4","status":200}
```

## Querying in Grafana

JSON logs enable powerful filtering in Loki:

```logql
# All errors from an app
{container="sgos-xhosa-app"} | json | level="error"

# Slow requests (>500ms)
{container="sgos-xhosa-app"} | json | duration_ms > 500

# Specific user's activity
{server="hornbill"} | json | user_id="stefan@sonnenglas.net"

# Find by order ID across all apps
{server="hornbill"} | json | order_id=12345

# Error rate by container
sum(rate({server="hornbill"} | json | level="error" [5m])) by (container)
```

## Error Tracking

For exceptions and errors that need attention, also send to GlitchTip:

```python
import sentry_sdk

sentry_sdk.init(
    dsn="https://...@glitchtip.sgl.as/1",
    traces_sample_rate=0.1,
)
```

**Logs** = operational visibility (what happened)
**GlitchTip** = error alerting (what broke)

## Uvicorn Access Logs

Uvicorn's default access logs are plain text. Options:

1. **Keep default** - simple, readable in development
2. **Disable** - if your middleware logs requests
3. **JSON format** - for consistency (requires custom config)

For most apps, keeping default is fine since you're adding structured logs in the application layer.

## Don'ts

- **Don't log sensitive data** - passwords, tokens, full credit card numbers
- **Don't log PII unnecessarily** - only when needed for debugging
- **Don't use print()** - use the logger
- **Don't log in tight loops** - aggregate or sample instead

#!/bin/bash
# Validate app.json has required fields for SGOS deployment
# Usage: validate-app.sh /path/to/app.json
# Exit codes: 0 = valid, 1 = invalid, 2 = file not found

set -e

APP_JSON="$1"

if [ -z "$APP_JSON" ]; then
    echo "Usage: validate-app.sh /path/to/app.json"
    exit 2
fi

if [ ! -f "$APP_JSON" ]; then
    echo "ERROR: app.json not found: $APP_JSON"
    exit 2
fi

ERRORS=0
WARNINGS=0

# Check required field exists and is not empty
check_required() {
    local field="$1"
    local desc="$2"
    local value=$(jq -r "$field // empty" "$APP_JSON")
    if [ -z "$value" ]; then
        echo "ERROR: Missing required field: $field ($desc)"
        ERRORS=$((ERRORS + 1))
    fi
}

# Check optional field (warn if missing)
check_optional() {
    local field="$1"
    local desc="$2"
    local value=$(jq -r "$field // empty" "$APP_JSON")
    if [ -z "$value" ]; then
        echo "WARN: Missing optional field: $field ($desc)"
        WARNINGS=$((WARNINGS + 1))
    fi
}

echo "Validating: $APP_JSON"
echo "---"

# Required fields
check_required '.name' 'App identifier'
check_required '.version' 'Semantic version'
check_required '.sgos.server' 'Target deployment server'
check_required '.sgos.domain' 'Public domain'

# Backup configuration (required)
check_required '.scripts.backup' 'Backup script command'
check_required '.sgos.backup.output' 'Backup output directory'

# Optional but recommended
check_optional '.description' 'App description'
check_optional '.repository' 'Source repository URL'
check_optional '.migration' 'Migration safety level (safe/breaking)'

echo "---"

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: $ERRORS error(s), $WARNINGS warning(s)"
    exit 1
fi

if [ $WARNINGS -gt 0 ]; then
    echo "PASSED with $WARNINGS warning(s)"
else
    echo "PASSED: All required fields present"
fi

exit 0

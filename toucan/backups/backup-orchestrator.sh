#!/bin/bash
# Backup orchestrator - runs nightly via cron on Toucan
# Collects backups from all SGOS apps, syncs to R2 via restic
#
# Cron entry (on Toucan):
#   0 3 * * * /srv/services/backups/backup-orchestrator.sh >> /srv/backups/cron.log 2>&1
#
# Each app must have a backup.sh script that creates backups in its backups/ directory.
# This orchestrator:
#   1. SSHs to each server and runs the app's backup.sh
#   2. Rsyncs the backup files to Toucan staging (organized by date)
#   3. Cleans up staging backups older than 7 days
#   4. Uses restic to sync everything to Cloudflare R2
#   5. Prunes old R2 snapshots (keeps 7 daily, 4 weekly, 3 monthly)
#
# Retention:
#   - Hornbill (source):  7 days local
#   - Toucan (staging):   7 days (date-organized: staging/<app>/YYYY-MM-DD/)
#   - Cloudflare R2:      7 daily, 4 weekly, 3 monthly via restic

set -e

# Load environment (R2 credentials, restic password)
source /srv/services/backups/.env
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY RESTIC_REPOSITORY RESTIC_PASSWORD

# Configuration
LOG_FILE="/srv/backups/backup.log"
STATUS_FILE="/srv/backups/status.json"
STAGING_DIR="/srv/backups/staging"
SSH_KEY="/home/stefan/.ssh/deploy_hornbill"
HORNBILL="stefan@100.67.57.25"
RETENTION_DAYS=7
TODAY=$(date +%Y-%m-%d)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

update_status() {
    local app="$1"
    local status="$2"
    local message="$3"
    jq --arg app "$app" --arg status "$status" --arg msg "$message" --arg ts "$(date -Iseconds)" \
        '.apps[$app] = {status: $status, message: $msg, timestamp: $ts}' \
        "$STATUS_FILE" > "$STATUS_FILE.tmp" && mv "$STATUS_FILE.tmp" "$STATUS_FILE"
}

cleanup_old_backups() {
    local app="$1"
    local app_staging="$STAGING_DIR/$app"

    log "Cleaning up old backups for $app (keeping $RETENTION_DAYS days)..."

    # Find and remove directories older than RETENTION_DAYS
    if [ -d "$app_staging" ]; then
        find "$app_staging" -maxdepth 1 -type d -name "20*" -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true

        # Count remaining backups
        local count=$(find "$app_staging" -maxdepth 1 -type d -name "20*" | wc -l)
        log "$app: $count backup(s) retained in staging"
    fi
}

backup_app() {
    local app="$1"
    local server="$2"
    local ssh_target="$3"
    local backup_path="/srv/apps/$app/backups"
    local today_staging="$STAGING_DIR/$app/$TODAY"

    log "Backing up $app from $server..."
    update_status "$app" "running" "Executing backup script"

    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$ssh_target" "/srv/apps/$app/src/backup.sh" 2>&1 | tee -a "$LOG_FILE"; then
        log "$app backup script completed"

        # Create date-organized directory for today's backup
        mkdir -p "$today_staging"
        if rsync -avz -e "ssh -i $SSH_KEY" "$ssh_target:$backup_path/" "$today_staging/" 2>&1 | tee -a "$LOG_FILE"; then
            update_status "$app" "collected" "Files synced to staging ($TODAY)"

            # Clean up old backups
            cleanup_old_backups "$app"
            return 0
        else
            update_status "$app" "error" "rsync failed"
            return 1
        fi
    else
        update_status "$app" "error" "Backup script failed"
        return 1
    fi
}

# Initialize status file if missing
[ -f "$STATUS_FILE" ] || echo '{"apps":{}}' > "$STATUS_FILE"

log "=========================================="
log "=== Starting backup run ==="
log "=========================================="

# Track overall success
BACKUP_ERRORS=0

# --- Hornbill Apps ---

# sgos-phone
if ! backup_app "sgos-phone" "hornbill" "$HORNBILL"; then
    BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
fi

# sgos-docflow
if ! backup_app "sgos-docflow" "hornbill" "$HORNBILL"; then
    BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
fi

# --- Add more apps here as they are deployed ---
# Example:
# if ! backup_app "sgos-newapp" "hornbill" "$HORNBILL"; then
#     BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
# fi

# --- Restic to R2 ---
log "Syncing to R2 via restic..."
if restic backup "$STAGING_DIR" --tag "daily" 2>&1 | tee -a "$LOG_FILE"; then
    log "Restic backup completed"

    # Update all collected apps to success
    for app in sgos-phone sgos-docflow; do
        current_status=$(jq -r ".apps[\"$app\"].status" "$STATUS_FILE")
        if [ "$current_status" = "collected" ]; then
            update_status "$app" "success" "Backed up to R2"
        fi
    done

    # Prune old snapshots (keep 7 daily, 4 weekly, 3 monthly)
    log "Pruning old snapshots..."
    restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune 2>&1 | tee -a "$LOG_FILE"
else
    log "ERROR: Restic backup failed"
    for app in sgos-phone sgos-docflow; do
        current_status=$(jq -r ".apps[\"$app\"].status" "$STATUS_FILE")
        if [ "$current_status" = "collected" ]; then
            update_status "$app" "error" "Restic sync failed"
        fi
    done
    BACKUP_ERRORS=$((BACKUP_ERRORS + 1))
fi

log "=========================================="
if [ $BACKUP_ERRORS -eq 0 ]; then
    log "=== Backup run complete (success) ==="
else
    log "=== Backup run complete with $BACKUP_ERRORS error(s) ==="
fi
log "=========================================="

exit $BACKUP_ERRORS

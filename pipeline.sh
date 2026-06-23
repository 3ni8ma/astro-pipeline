#!/usr/bin/env bash
set -euo pipefail

PIPELINE_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$PIPELINE_DIR/lib"
CONTRIB_DIR="$PIPELINE_DIR/contributions"
LOG_FILE="$PIPELINE_DIR/pipeline.log"

export PIPELINE_DIR LIB_DIR CONTRIB_DIR LOG_FILE

# Config from environment (set by GHA workflow, not .env)
export GIT_AUTHOR_NAME="${GIT_NAME:-Aarush Karak}"
export GIT_AUTHOR_EMAIL="${GIT_EMAIL}"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
export GITHUB_USER="${GITHUB_USER:-3ni8ma}"
export PROFILE_REPO_DIR="${PROFILE_REPO_DIR:-$HOME/3ni8ma}"
export REPOS_DIR="${REPOS_DIR:-$HOME}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Skip lockfile in GHA (serialized by runner), use locally
if [ -z "${CI:-}" ]; then
  LOCKFILE="$PIPELINE_DIR/pipeline.lock"
  if ! mkdir "$LOCKFILE" 2>/dev/null; then
    log "Previous run still in progress (lockfile exists), skipping."
    exit 0
  fi
  trap "rmdir '$LOCKFILE' 2>/dev/null" EXIT
fi

log "=== Pipeline Started ==="

source "$LIB_DIR/fetch-stats.sh"
source "$LIB_DIR/update-readme.sh"
source "$LIB_DIR/generate-svgs.sh"
source "$LIB_DIR/trigger-workflows.sh"
source "$LIB_DIR/contribute.sh"
source "$LIB_DIR/heartbeats.sh"
source "$LIB_DIR/gmail.sh"
source "$LIB_DIR/linkedin.sh"

make_daily_contributions
fetch_github_stats
update_profile_readme
generate_profile_svgs
trigger_github_workflows
send_heartbeats
gmail_read_coding_notifications
send_daily_summary
check_linkedin

log "=== Pipeline Completed ==="

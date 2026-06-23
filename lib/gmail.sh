#!/usr/bin/env bash

GMAIL_PY="$LIB_DIR/gmail.py"

gmail_auth_check() {
  if [ ! -f "$PIPELINE_DIR/.gmail/app-password" ]; then
    log "Gmail: No app password found. Run: python3 .setup/gmail-setup.py"
    return 1
  fi
  return 0
}

send_daily_summary() {
  if ! gmail_auth_check; then return; fi

  log "Sending daily summary email..."

  local stars=$(get_stat stars)
  local contribs=$(get_stat total_contributions)
  local streak=$(get_stat current_streak)
  local repos=$(get_stat public_repos)
  local followers=$(get_stat followers)
  local commits=$(get_stat commits)
  local prs=$(get_stat pull_requests)
  local issues=$(get_stat issues)
  local reviews=$(get_stat reviews)

  local heartbeat_info=$(grep "Prepared.*heartbeats" "$LOG_FILE" 2>/dev/null | tail -1 | sed "s/.*\][[:space:]]*//")

  local astro_info=""
  if command -v astro &>/dev/null; then
    astro_info=$(astro log 2>/dev/null | grep -v "^$" | head -20 | while IFS= read -r line; do echo "  $line"; done)
  fi

  python3 -c "
import sys
sys.path.insert(0, '$LIB_DIR')
from gmail import send_daily_summary
send_daily_summary(
    stars=$stars,
    contribs=$contribs,
    streak=$streak,
    repos=$repos,
    followers=$followers,
    commits=$commits,
    prs=$prs,
    issues=$issues,
    reviews=$reviews,
    heartbeat_info='$heartbeat_info',
    astro_info='''$astro_info'''
)
" 2>&1 | while IFS= read -r line; do log "$line"; done

  log "Daily summary sent."
}

gmail_read_coding_notifications() {
  if ! gmail_auth_check; then return; fi

  log "Checking for coding-related emails..."

  python3 -c "
import sys
sys.path.insert(0, '$LIB_DIR')
from gmail import read_coding_emails
items = read_coding_emails(max_results=5)
if items:
    for item in items:
        print(f'  [{item[\"date\"]}] {item[\"from\"]} - {item[\"subject\"]}')
" 2>&1 | while IFS= read -r line; do log "$line"; done
}

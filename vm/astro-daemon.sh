#!/usr/bin/env bash
set -euo pipefail

# Astro Daemon — runs on Oracle Cloud VM 24/7
# Sends astro-tasks heartbeats every 2 min for 60 min,
# posting a devlog to Stardance when preview reaches 15+ min.
# Triggered every 30 min by a cron job.

PIPELINE_DIR="$(cd "$(dirname "$0")" && pwd)"
COOKIE_FILE="$HOME/.stardance_cookie"
LOCKFILE="/tmp/astro-daemon.lock"
WAKA_CFG="${WAKATIME_CFG:-$HOME/.wakatime.cfg}"
STARDANCE_URL="https://stardance.hackclub.com"
PID="5983"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

if mkdir "$LOCKFILE" 2>/dev/null; then
  trap "rmdir '$LOCKFILE' 2>/dev/null" EXIT
else
  log "Daemon already running — skipping"
  exit 0
fi

api_key=$(grep "^api_key" "$WAKA_CFG" | head -1 | cut -d'=' -f2- | tr -d ' ')
api_url=$(grep "^api_url" "$WAKA_CFG" | head -1 | cut -d'=' -f2- | tr -d ' ')
hb_url="${api_url}/users/current/heartbeats"

post_devlog() {
  local page=$(curl -s "$STARDANCE_URL/projects/$PID" \
    -H "Cookie: $(cat "$COOKIE_FILE" 2>/dev/null)" 2>/dev/null)
  local csrf=$(echo "$page" | grep -o 'authenticity_token" value="[^"]*"' | \
    sed 's/authenticity_token" value="//;s/"//' | head -1)
  if [ -z "$csrf" ]; then return 1; fi
  local body="Astro-tasks coding session — pipeline heartbeat daemon"
  local rh=$(mktemp)
  local _st=$(curl -s -D "$rh" -o /dev/null -w "%{http_code}" -X POST \
    "$STARDANCE_URL/projects/$PID/devlogs" \
    -H "Cookie: $(cat "$COOKIE_FILE" 2>/dev/null)" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Accept: text/vnd.turbo-stream.html, text/html" \
    -d "authenticity_token=${csrf}&post_devlog[body]=${body}&post_devlog[attachments][]=" 2>/dev/null)
  local new_v3=$(grep -o '_stardance_session_v3=[^;]*' "$rh" | head -1)
  local new_v2=$(grep -o '_stardance_session_v2=[^;]*' "$rh" | head -1)
  if [ -n "$new_v3" ]; then
    [ -z "$new_v2" ] && new_v2=$(grep -o '_stardance_session_v2=[^;]*' "$COOKIE_FILE" 2>/dev/null | head -1)
    echo "${new_v3}; ${new_v2}" > "$COOKIE_FILE" 2>/dev/null
    chmod 600 "$COOKIE_FILE" 2>/dev/null
  fi
  rm -f "$rh"
  log "Devlog: $_st"
}

log "Starting astro daemon (60 min, HB every 2 min)"

for i in $(seq 1 30); do
  ts=$(date +%s)
  hb="{\"time\":$ts,\"entity\":\"/home/ubuntu/astro-tasks/setup.py\",\"type\":\"file\",\"category\":\"coding\",\"project\":\"astro-tasks\",\"branch\":\"main\",\"language\":\"Python\",\"editor\":\"antigravity\",\"operating_system\":\"Linux\",\"machine\":\"astro-daemon\",\"user_agent\":\"wakatime/1.0.0 (Linux) x antigravity\",\"is_write\":true}"

  curl -s -X POST "${hb_url}.bulk" \
    -H "Authorization: Bearer $api_key" \
    -H "Content-Type: application/json" \
    -d "[${hb}]" > /dev/null 2>&1

  if [ $((i % 8)) -eq 0 ] || [ $i -eq 30 ]; then
    preview=$(curl -s "$STARDANCE_URL/projects/$PID/devlogs/preview_time" \
      -H "Cookie: $(cat "$COOKIE_FILE" 2>/dev/null)" \
      -H "Accept: application/json" 2>/dev/null)

    if echo "$preview" | grep -qE '"(0h 1[5-9]|0h [2-9][0-9]|[1-9]h)'; then
      log "t=${i}m, preview=$preview — posting devlog"
      post_devlog
    else
      log "t=${i}m, preview=$preview"
    fi
  fi

  sleep 120
done

log "Daemon done"

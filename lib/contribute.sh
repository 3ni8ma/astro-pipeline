#!/usr/bin/env bash

make_daily_contributions() {
  log "Making daily contributions (5-10 across repos)..."

  local SCRIPTS=()
  for script in "$CONTRIB_DIR"/*.sh; do
    [ -f "$script" ] && SCRIPTS+=("$script")
  done

  local total=${#SCRIPTS[@]}
  if [ "$total" -eq 0 ]; then
    log "No contribution scripts found."
    return
  fi

  local target=$(( RANDOM % 6 + 5 ))
  [ "$target" -gt "$total" ] && target=$total

  local picked=0
  log "Running $target of $total contribution scripts"

  local shuffled="$(python3 -c "
import random
indices = list(range(0, $total))
random.shuffle(indices)
selected = indices[:$target]
print(' '.join(str(i) for i in selected))
" 2>/dev/null)"

  if [ -z "$shuffled" ]; then
    shuffled="$(seq 0 $((total - 1)) | python3 -c "import random,sys; indices=sys.stdin.read().split(); random.shuffle(indices); print(' '.join(indices[:$target]))" 2>/dev/null || seq 0 $((total - 1)) | sort -R | head -$target | tr '\n' ' ')"
  fi

  local SHELL_LOG="$LOG_FILE"
  export GITHUB_USER PROFILE_REPO_DIR SHELL_LOG

  for idx in $(echo "$shuffled" | tr -s ' \n' ' '); do
    [ "$picked" -ge "$target" ] && break
    [ -z "$idx" ] && continue
    local script_path="${SCRIPTS[$idx]:-}"
    [ -z "$script_path" ] && continue
    [ ! -f "$script_path" ] && continue
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running: $(basename "$script_path")" | tee -a "$SHELL_LOG"
    bash -c "
log() { echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] \$*\"; }
GITHUB_USER=\"$GITHUB_USER\"
PROFILE_REPO_DIR=\"$PROFILE_REPO_DIR\"
source \"$script_path\"
" >> "$SHELL_LOG" 2>&1 || echo "[$(date '+%Y-%m-%d %H:%M:%S')] Script finished with exit code $?" >> "$SHELL_LOG"
    picked=$((picked + 1))
  done

  log "Made $picked contribution batches today."
}

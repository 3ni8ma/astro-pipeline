#!/usr/bin/env bash
set -euo pipefail

REPO="$GITHUB_USER/astro-tasks"
DIR="$REPOS_DIR/astro-tasks"

if [ ! -d "$DIR" ]; then
  gh repo clone "$REPO" "$DIR"
fi

cd "$DIR"
git checkout main 2>/dev/null || git checkout master 2>/dev/null || true
git pull origin HEAD 2>&1 | tee -a "$LOG_FILE"

cat > VERSION << VERSIONEOF
0.1.0
Last updated: $(date -u '+%Y-%m-%d %H:%M UTC')
VERSIONEOF

git add -A

git diff --staged --quiet || (
  git commit -m "Update astro-tasks: $(date '+%Y-%m-%d %H:%M') [skip ci]"
  git push origin HEAD 2>&1 | tee -a "$LOG_FILE"
  log "astro-tasks: Updated and pushed."
) || log "astro-tasks: No changes."

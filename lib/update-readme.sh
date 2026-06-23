#!/usr/bin/env bash

update_profile_readme() {
  log "Updating profile README with live stats..."

  if [ ! -d "$PROFILE_REPO_DIR" ]; then
    log "Cloning profile repo..."
    gh repo clone "$GITHUB_USER/$GITHUB_USER" "$PROFILE_REPO_DIR" 2>&1 | tee -a "$LOG_FILE"
  fi

  cd "$PROFILE_REPO_DIR"

  git checkout main 2>/dev/null || git checkout master 2>/dev/null || true
  git fetch origin 2>&1 | tee -a "$LOG_FILE"
  git reset --hard origin/main 2>/dev/null || git reset --hard origin/master 2>/dev/null || true

  local stars=$(get_stat stars)
  local contribs=$(get_stat total_contributions)
  local streak=$(get_stat current_streak)
  local repos=$(get_stat public_repos)
  local followers=$(get_stat followers)

  local streak_label="${streak}%20Day"
  [ "$streak" != "1" ] && streak_label="${streak}%20Days"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|Contributions-[0-9]*|Contributions-$contribs|" README.md
    sed -i '' "s|Stars-[0-9]*|Stars-$stars|" README.md
    sed -i '' "s|Streak-[0-9]*%20Days\{0,1\}|Streak-$streak_label|" README.md
  else
    sed -i "s|Contributions-[0-9]*|Contributions-$contribs|" README.md
    sed -i "s|Stars-[0-9]*|Stars-$stars|" README.md
    sed -i "s|Streak-[0-9]*%20Days\\{0,1\\}|Streak-$streak_label|" README.md
  fi

  if git diff --quiet README.md; then
    log "No README changes needed."
  else
    git add README.md
    git commit -m "Update profile stats: $contribs contribs, $stars stars, $streak day streak [skip ci]"
    git push origin HEAD 2>&1 | tee -a "$LOG_FILE"
    log "README updated and pushed."
  fi

  cd "$PIPELINE_DIR"
}

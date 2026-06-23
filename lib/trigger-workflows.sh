#!/usr/bin/env bash

trigger_github_workflows() {
  log "Triggering GitHub Actions workflows..."

  local snake_run=$(gh workflow run snake.yml --repo "$GITHUB_USER/$GITHUB_USER" 2>&1) || true
  if echo "$snake_run" | grep -q "https://"; then
    log "Snake workflow triggered: $(echo "$snake_run" | grep -o 'https://[^ ]*')"
  else
    log "Snake workflow trigger result: $snake_run"
  fi

  sleep 2

  local profile_run=$(gh workflow run profile-3d.yml --repo "$GITHUB_USER/$GITHUB_USER" 2>&1) || true
  if echo "$profile_run" | grep -q "https://"; then
    log "3D Contrib workflow triggered: $(echo "$profile_run" | grep -o 'https://[^ ]*')"
  else
    log "3D Contrib workflow trigger result: $profile_run"
  fi
}

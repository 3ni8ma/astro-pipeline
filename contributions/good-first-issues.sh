#!/usr/bin/env bash
set -euo pipefail

log "Searching for good-first-issues matching your stack..."

repos=(
  "facebook/react"
  "vercel/next.js"
  "tailwindlabs/tailwindcss"
  "vitejs/vite"
  "monaco-editor/monaco-editor"
  "microsoft/TypeScript"
  "prisma/prisma"
  "framer/motion"
  "pmndrs/zustand"
  "radix-ui/primitives"
)

found=0
for repo in "${repos[@]}"; do
  [ $found -ge 2 ] && break

  issues=$(gh issue list --repo "$repo" --label "good first issue,help wanted" --limit 5 --json number,title,url,state,labels 2>/dev/null || echo "[]")

  if [ "$issues" = "[]" ] || [ -z "$issues" ]; then
    continue
  fi

  count=$(echo "$issues" | jq length 2>/dev/null || echo 0)
  if [ "$count" -eq 0 ]; then
    continue
  fi

  for i in $(seq 0 $((count - 1))); do
    [ $found -ge 2 ] && break
    title=$(echo "$issues" | jq -r ".[$i].title" 2>/dev/null || echo "")
    url=$(echo "$issues" | jq -r ".[$i].url" 2>/dev/null || echo "")
    number=$(echo "$issues" | jq -r ".[$i].number" 2>/dev/null || echo "")

    if [ -n "$title" ] && [ "$title" != "null" ]; then
      log "  Found: [$repo#$number] $title"
      log "    $url"
      found=$((found + 1))
    fi
  done
done

if [ "$found" -eq 0 ]; then
  log "No good-first-issues found today. Will focus on personal repos."
fi

log "Issue discovery complete. Found $found candidate issues."

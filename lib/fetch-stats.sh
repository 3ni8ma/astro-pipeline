#!/usr/bin/env bash


STATS_CACHE="$PIPELINE_DIR/stats.json"

fetch_github_stats() {
  log "Fetching GitHub stats for $GITHUB_USER..."

  local stars=$(gh api users/$GITHUB_USER/repos --paginate --jq '[.[] | select(.fork==false) | .stargazers_count] | add // 0' 2>/dev/null || echo "0")

  local total_contribs=$(gh api graphql -f query='
    query { user(login: "'$GITHUB_USER'") { contributionsCollection { contributionCalendar { totalContributions } } } }
  ' --jq '.data.user.contributionsCollection.contributionCalendar.totalContributions' 2>/dev/null || echo "0")

  local streak_data=$(gh api graphql -f query='
    query {
      user(login: "'$GITHUB_USER'") {
        contributionsCollection {
          contributionCalendar {
            weeks {
              contributionDays {
                contributionCount
                date
              }
            }
          }
        }
      }
    }' --jq '[.data.user.contributionsCollection.contributionCalendar.weeks[].contributionDays[]] | sort_by(.date) | reverse' 2>/dev/null || echo "[]")

  local current_streak=0
  local streak_started=false
  for row in $(echo "$streak_data" | jq -c '.[]'); do
    local count=$(echo "$row" | jq '.contributionCount')
    if [ "$count" -gt 0 ] 2>/dev/null; then
      streak_started=true
      current_streak=$((current_streak + 1))
    else
      if [ "$streak_started" = true ]; then
        break
      fi
    fi
  done

  local public_repos=$(gh api users/$GITHUB_USER --jq '.public_repos' 2>/dev/null || echo "0")
  local followers=$(gh api users/$GITHUB_USER --jq '.followers' 2>/dev/null || echo "0")

  local contrib_types=$(gh api graphql -f query='
    query { user(login: "'$GITHUB_USER'") { contributionsCollection { totalCommitContributions totalPullRequestContributions totalIssueContributions totalPullRequestReviewContributions } } }
  ' --jq '.data.user.contributionsCollection' 2>/dev/null || echo '{"totalCommitContributions":0,"totalPullRequestContributions":0,"totalIssueContributions":0,"totalPullRequestReviewContributions":0}')

  local commits=$(echo "$contrib_types" | jq -r '.totalCommitContributions')
  local prs=$(echo "$contrib_types" | jq -r '.totalPullRequestContributions')
  local issues=$(echo "$contrib_types" | jq -r '.totalIssueContributions')
  local reviews=$(echo "$contrib_types" | jq -r '.totalPullRequestReviewContributions')

  cat > "$STATS_CACHE" << EOF
{
  "stars": $stars,
  "total_contributions": $total_contribs,
  "current_streak": $current_streak,
  "public_repos": $public_repos,
  "followers": $followers,
  "commits": $commits,
  "pull_requests": $prs,
  "issues": $issues,
  "reviews": $reviews,
  "fetched_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

  log "Stats: $(echo "$stars" | tr -d '\n') stars, $(echo "$total_contribs" | tr -d '\n') contributions, $(echo "$current_streak" | tr -d '\n') day streak"
}

get_stat() {
  jq -r ".$1 // 0" "$STATS_CACHE" 2>/dev/null || echo "0"
}

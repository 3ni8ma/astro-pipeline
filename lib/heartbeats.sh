#!/usr/bin/env bash

send_heartbeats() {
  local waka_cfg="${WAKATIME_CFG:-$HOME/.wakatime.cfg}"

  if [ ! -f "$waka_cfg" ]; then
    log "No WakaTime config found at $waka_cfg"
    return
  fi

  log "Sending heartbeats to Hackatime..."

  local tmpfile=$(mktemp)
  local curl_config=$(mktemp)
  trap "rm -f $tmpfile $curl_config" EXIT

  local repos_dir="${REPOS_DIR:-$HOME}"

  python3 -u -c "
import os, json, subprocess, time, configparser
from datetime import datetime

cfg_path = '$waka_cfg'
config = configparser.ConfigParser()
config.read(cfg_path)
api_key = config.get('settings', 'api_key', fallback=None)
api_url = config.get('settings', 'api_url', fallback=None)

if not api_key or not api_url:
    print('No API config found')
    exit(0)

tmpfile = '$tmpfile'
now = int(time.time())

repos = [
    ('$repos_dir/3ni8ma', '3ni8ma', 'Markdown'),
    ('$repos_dir/cli-tool', 'cli-tool', 'Python'),
    ('$repos_dir/TheCoderBros-Website', 'TheCoderBros-Website', 'TypeScript'),
    ('$repos_dir/aarushkarak-website', 'aarushkarak-website', 'TypeScript'),
    ('$repos_dir/react-hooks', 'react-hooks', 'TypeScript'),
    ('$repos_dir/tailwind-plugin', 'tailwind-plugin', 'TypeScript'),
    ('$repos_dir/vite-plugin', 'vite-plugin', 'TypeScript'),
    ('$repos_dir/HomeFixAI', 'HomeFixAI', 'Python'),
    ('$repos_dir/openhuman', 'openhuman', 'TypeScript'),
]

fallback_files = {
    '3ni8ma': ['README.md'],
    'cli-tool': ['src/main.py'],
    'TheCoderBros-Website': ['src/app/page.tsx'],
    'aarushkarak-website': ['src/pages/index.tsx'],
    'react-hooks': ['src/index.ts'],
    'tailwind-plugin': ['src/index.ts'],
    'vite-plugin': ['src/index.ts'],
    'HomeFixAI': ['main.py'],
    'openhuman': ['src/index.ts'],
}

heartbeats = []
for repo_dir, project, lang in repos:
    branch = 'main'
    try:
        branch = subprocess.check_output(
            ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
            cwd=repo_dir, stderr=subprocess.DEVNULL
        ).decode().strip()
    except:
        pass
    for f in fallback_files.get(project, []):
        fpath = os.path.join(repo_dir, f)
        if os.path.isfile(fpath):
            lines = 0
            try:
                with open(fpath) as fh:
                    lines = sum(1 for _ in fh)
            except:
                pass
            heartbeats.append({
                'time': now,
                'entity': fpath,
                'type': 'file',
                'category': 'coding',
                'project': project,
                'branch': branch,
                'language': lang,
                'editor': 'antigravity',
                'operating_system': 'Linux',
                'machine': 'astro-pipeline',
                'user_agent': 'wakatime/1.0.0 (Linux) x antigravity',
                'is_write': True,
                'lines': lines if lines > 0 else None,
            })

if not heartbeats:
    print('No files to track')
    exit(0)

with open(tmpfile, 'w') as f:
    json.dump(heartbeats, f)

proj_str = ', '.join(sorted(set(h['project'] for h in heartbeats)))
print(f'Sending {len(heartbeats)} current heartbeats for {len(set(h[\"project\"] for h in heartbeats))} projects: {proj_str}')
" 2>&1 | while IFS= read -r line; do log "$line"; done

  if [ ! -s "$tmpfile" ]; then
    log "No heartbeats to send"
    return
  fi

  local api_key=$(grep "^api_key" "$waka_cfg" | head -1 | cut -d'=' -f2- | tr -d ' ')
  local api_url=$(grep "^api_url" "$waka_cfg" | head -1 | cut -d'=' -f2- | tr -d ' ')
  if [ -z "$api_key" ] || [ -z "$api_url" ]; then
    log "Heartbeat config error"
    return
  fi
  local hb_url="${api_url}/users/current/heartbeats"

  cat > "$curl_config" << EOF
header = "Authorization: Bearer $api_key"
header = "X-Machine-Name: astro-pipeline"
header = "Content-Type: application/json"
EOF

  local response=$(curl -s -X POST "${hb_url}.bulk" -K "$curl_config" -d @"$tmpfile" 2>&1)
  local result=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    responses = data.get('responses', [])
    accepted = sum(1 for r in responses if len(r) > 1 and r[1] == 201)
    print('Heartbeats sent: {} accepted / {} total'.format(accepted, len(responses)))
except Exception as e:
    print('Response: {}'.format(str(e)))
" 2>/dev/null)
  log "${result:-$response}"
}

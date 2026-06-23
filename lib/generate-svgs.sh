#!/usr/bin/env bash

generate_profile_svgs() {
  log "Generating profile SVGs..."

  if [ ! -d "$PROFILE_REPO_DIR" ]; then
    log "Profile repo not cloned, skipping SVG generation."
    return
  fi

  cd "$PROFILE_REPO_DIR"
  git fetch origin 2>&1 | tee -a "$LOG_FILE"
  git reset --hard origin/main 2>/dev/null || git reset --hard origin/master 2>/dev/null || true

  local stars=$(get_stat stars)
  local contribs=$(get_stat total_contributions)
  local streak=$(get_stat current_streak)
  local repos=$(get_stat public_repos)
  local followers=$(get_stat followers)
  local commits=$(get_stat commits)
  local prs=$(get_stat pull_requests)
  local issues=$(get_stat issues)
  local reviews=$(get_stat reviews)

  log "Rendering SVGs with stats: stars=$stars contribs=$contribs streak=$streak repos=$repos followers=$followers"

  python3 << PYEOF
import os, json

stars = $stars
contribs = $contribs
streak = $streak
repos = $repos
followers = $followers
commits = $commits
pull_requests = $prs
issues = $issues
reviews = $reviews
profile_dir = "$PROFILE_REPO_DIR"

def write_svg(filename, content):
    path = os.path.join(profile_dir, filename)
    with open(path, 'w') as f:
        f.write(content)
    print(f"  Wrote {filename}")

# === RADAR SVG (3D Bar Chart) ===
import datetime

bars = [
    ("Commits", commits, "#D946EF"),
    ("Pull Requests", pull_requests, "#6366F1"),
    ("Issues", issues, "#F59E0B"),
    ("Code Reviews", reviews, "#22D3EE"),
]

max_val = max([v for _, v, _ in bars])
if max_val < 10: max_val = 10
chart_h = 240
bar_w = 130
gap = 30
x_start = 55
floor_y = 330

bar3d = ""
for i, (name, val, color) in enumerate(bars):
    bh = int(chart_h * val / max_val) if val > 0 else 2
    if bh < 2:
        bh = 2
    bx = x_start + i * (bar_w + gap)
    by = floor_y - bh

    r, g, b = int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16)
    top = f"rgba({r},{g},{b},0.5)"
    side = f"rgba({r},{g},{b},0.25)"

    d = 10
    bar3d += f'''  <!-- {name} bar -->
  <rect x="{bx}" y="{by}" width="{bar_w}" height="{bh}" rx="4" fill="{color}"/>
  <polygon points="{bx+d},{by-d} {bx+bar_w+d},{by-d} {bx+bar_w},{by} {bx},{by}" fill="{top}" stroke="none"/>
  <polygon points="{bx+bar_w},{by} {bx+bar_w+d},{by-d} {bx+bar_w+d},{floor_y-d} {bx+bar_w},{floor_y}" fill="{side}" stroke="none"/>
'''

    if val > 0:
        bar3d += f'''  <rect x="{bx}" y="{by}" width="{bar_w}" height="{bh}" rx="4" fill="url(#glow)" opacity="0.3"/>
'''

    bar3d += f'''  <text x="{bx+bar_w//2}" y="{by-14}" text-anchor="middle" fill="{color}" font-family="system-ui,-apple-system,sans-serif" font-size="16" font-weight="800">{val}</text>
  <text x="{bx+bar_w//2}" y="{floor_y+16}" text-anchor="middle" fill="#666" font-family="system-ui,-apple-system,sans-serif" font-size="11">{name}</text>
'''

# Floor grid lines
grid = ""
for y in range(floor_y - 40, floor_y, 40):
    grid += f'  <line x1="{x_start}" y1="{y}" x2="{x_start+4*(bar_w+gap)-gap}" y2="{y}" stroke="#1a1a1a" stroke-width="1" stroke-dasharray="3,3"/>\n'

ts = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d %H:%M UTC')

radar_svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 400" width="800" height="400">
<defs>
  <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
    <stop offset="0%" stop-color="#0c0c0c"/><stop offset="100%" stop-color="#050505"/>
  </linearGradient>
  <linearGradient id="glow" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#fff" stop-opacity="0.4"/>
    <stop offset="100%" stop-color="#fff" stop-opacity="0"/>
  </linearGradient>
  <filter id="shadow">
    <feDropShadow dx="0" dy="4" stdDeviation="6" flood-color="#000" flood-opacity="0.4"/>
  </filter>
</defs>
<rect width="800" height="400" fill="url(#bg)" rx="16"/>

<!-- Header -->
<rect x="0" y="0" width="800" height="42" fill="#111" rx="16"/>
<rect x="0" y="26" width="800" height="16" fill="#111"/>
<text x="400" y="27" text-anchor="middle" fill="#6366F1" font-family="system-ui,-apple-system,sans-serif" font-size="12" font-weight="700" letter-spacing="3">CONTRIBUTION BREAKDOWN</text>

<!-- Chart area -->
<g transform="translate(0,10)">
  <!-- Floor -->
  <rect x="{x_start-10}" y="{floor_y}" width="{4*(bar_w+gap)-gap+20}" height="2" rx="1" fill="#222"/>
  <!-- Grid lines -->
{grid}

  <!-- Bars -->
  <g filter="url(#shadow)">
{bar3d}
  </g>
</g>

<!-- Stats panel -->
<rect x="485" y="62" width="290" height="310" rx="12" fill="#111" stroke="#1a1a1a" stroke-width="1"/>
<text x="505" y="90" fill="#fff" font-family="system-ui,-apple-system,sans-serif" font-size="16" font-weight="700">Overview</text>
<line x1="505" y1="105" x2="755" y2="105" stroke="#1f1f1f" stroke-width="1"/>

'''
y = 125
items = [("Stars", str(stars), "#22D3EE"), ("Contributions", str(contribs), "#D946EF"),
         ("Repos", str(repos), "#6366F1"), ("Streak", f"{streak}d", "#22D3EE"),
         ("Followers", str(followers), "#D946EF")]
for label, val, col in items:
    radar_svg += f'''  <text x="505" y="{y+4}" fill="#666" font-family="system-ui,-apple-system,sans-serif" font-size="11">{label}</text>
  <text x="755" y="{y+4}" text-anchor="end" fill="{col}" font-family="system-ui,-apple-system,sans-serif" font-size="14" font-weight="800">{val}</text>
  <line x1="505" y1="{y+18}" x2="755" y2="{y+18}" stroke="#151515" stroke-width="1"/>
'''
    y += 26

y += 2
radar_svg += f'''
<text x="505" y="{y+2}" fill="#888" font-family="system-ui,-apple-system,sans-serif" font-size="9" font-weight="600" letter-spacing="1">CONTRIBUTION TYPES</text>
'''
y += 16
for name, val, color in bars:
    radar_svg += f'''  <rect x="505" y="{y}" width="7" height="7" rx="2" fill="{color}"/>
  <text x="518" y="{y+6}" fill="#555" font-family="system-ui,-apple-system,sans-serif" font-size="9">{name}</text>
  <text x="755" y="{y+6}" text-anchor="end" fill="{color}" font-family="system-ui,-apple-system,sans-serif" font-size="10" font-weight="600">{val}</text>
'''
    y += 16

radar_svg += f'''
<text x="630" y="358" text-anchor="middle" fill="#333" font-family="system-ui,-apple-system,sans-serif" font-size="8">Updated {ts}</text>
</svg>'''

write_svg('radar.svg', radar_svg)

# === ABOUT SVG ===
about_svg = f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 800 260" width="800" height="260">
<defs>
  <linearGradient id="name-grad" x1="0%" y1="0%" x2="100%" y2="0%">
    <stop offset="0%" stop-color="#D946EF"/>
    <stop offset="50%" stop-color="#6366F1"/>
    <stop offset="100%" stop-color="#22D3EE"/>
  </linearGradient>
</defs>
<rect width="800" height="260" fill="#0a0a0a" rx="16"/>
<g transform="translate(40, 36)">
  <text y="0" fill="url(#name-grad)" font-family="system-ui, sans-serif" font-size="28" font-weight="800">Aarush Karak</text>
  <text y="28" fill="#888" font-family="system-ui, sans-serif" font-size="14">Software Developer &amp; Student | Full-Stack &amp; Spatial Computing</text>
  <text y="52" fill="#555" font-family="system-ui, sans-serif" font-size="12">Greater Toronto Area, Canada</text>
  <rect y="72" width="720" height="1" fill="#1f1f1f"/>
  <text y="96" fill="#ccc" font-family="system-ui, sans-serif" font-size="14">Building the future of human-computer interaction through spatial computing,</text>
  <text y="116" fill="#ccc" font-family="system-ui, sans-serif" font-size="14">full-stack development, and open-source tools. Founder of The Coder Bros.</text>
  <text y="148" fill="#888" font-family="system-ui, sans-serif" font-size="13">GitHub Stats</text>
  <rect y="168" width="160" height="36" rx="8" fill="#151515"/>
  <text x="80" y="191" text-anchor="middle" fill="#D946EF" font-family="system-ui, sans-serif" font-size="14" font-weight="700">{stars}</text>
  <text x="80" y="206" text-anchor="middle" fill="#666" font-family="system-ui, sans-serif" font-size="9">STARS</text>
  <rect y="168" x="175" width="160" height="36" rx="8" fill="#151515"/>
  <text x="255" y="191" text-anchor="middle" fill="#6366F1" font-family="system-ui, sans-serif" font-size="14" font-weight="700">{contribs}</text>
  <text x="255" y="206" text-anchor="middle" fill="#666" font-family="system-ui, sans-serif" font-size="9">CONTRIBUTIONS</text>
  <rect y="168" x="350" width="160" height="36" rx="8" fill="#151515"/>
  <text x="430" y="191" text-anchor="middle" fill="#22D3EE" font-family="system-ui, sans-serif" font-size="14" font-weight="700">{followers}</text>
  <text x="430" y="206" text-anchor="middle" fill="#666" font-family="system-ui, sans-serif" font-size="9">FOLLOWERS</text>
</g>
</svg>'''

write_svg('about.svg', about_svg)

# === HEADER SVG ===
header_svg = '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 800 180" width="800" height="180">
<defs>
  <linearGradient id="header-grad" x1="0%" y1="0%" x2="100%" y2="100%">
    <stop offset="0%" stop-color="#D946EF"/>
    <stop offset="50%" stop-color="#6366F1"/>
    <stop offset="100%" stop-color="#22D3EE"/>
  </linearGradient>
  <linearGradient id="subtitle-grad" x1="0%" y1="0%" x2="100%" y2="0%">
    <stop offset="0%" stop-color="#888"/>
    <stop offset="50%" stop-color="#ccc"/>
    <stop offset="100%" stop-color="#888"/>
  </linearGradient>
</defs>
<rect width="800" height="180" fill="#0a0a0a" rx="16"/>
<g transform="translate(40, 50)">
  <text y="0" fill="url(#header-grad)" font-family="system-ui, sans-serif" font-size="40" font-weight="800" letter-spacing="1">3ni8ma</text>
  <text y="30" fill="url(#subtitle-grad)" font-family="system-ui, sans-serif" font-size="14" letter-spacing="3">SOFTWARE DEVELOPER \u00b7 FULL-STACK \u00b7 SPATIAL COMPUTING</text>
  <text y="56" fill="#555" font-family="system-ui, sans-serif" font-size="12">Aarush Karak \u00b7 The Coder Bros \u00b7 Toronto, Canada</text>
  <circle cx="0" cy="82" r="4" fill="#D946EF"/>
  <text x="12" y="86" fill="#888" font-family="system-ui, sans-serif" font-size="12">Building HELIOS \u2014 browser-native spatial OS</text>
  <circle cx="0" cy="104" r="4" fill="#6366F1"/>
  <text x="12" y="108" fill="#888" font-family="system-ui, sans-serif" font-size="12">Founder @ The Coder Bros \u2014 teaching 1000+ students</text>
  <circle cx="0" cy="126" r="4" fill="#22D3EE"/>
  <text x="12" y="130" fill="#888" font-family="system-ui, sans-serif" font-size="12">Open source \u00b7 React hooks \u00b7 Tailwind \u00b7 Vite \u00b7 CLI tools</text>
</g>
</svg>'''

write_svg('header.svg', header_svg)

# === EXPERIENCE SVG ===
exp_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 400" width="800" height="400">
<defs>
  <linearGradient id="exp-grad" x1="0%" y1="0%" x2="100%" y2="0%">
    <stop offset="0%" stop-color="#D946EF"/>
    <stop offset="50%" stop-color="#6366F1"/>
    <stop offset="100%" stop-color="#22D3EE"/>
  </linearGradient>
</defs>
<rect width="800" height="400" fill="#0a0a0a" rx="16"/>
<text x="400" y="36" text-anchor="middle" fill="#D946EF" font-family="system-ui, sans-serif" font-size="14" font-weight="600" letter-spacing="2">EXPERIENCE TIMELINE</text>
<line x1="100" y1="60" x2="100" y2="370" stroke="#1f1f1f" stroke-width="2"/>
<circle cx="100" cy="90" r="6" fill="#D946EF"/>
<text x="120" y="94" fill="#fff" font-family="system-ui, sans-serif" font-size="14" font-weight="600">Founder \u2014 The Coder Bros</text>
<text x="120" y="112" fill="#888" font-family="system-ui, sans-serif" font-size="12">Jun 2025 \u2014 Present</text>
<text x="120" y="132" fill="#666" font-family="system-ui, sans-serif" font-size="12">Teaching coding to 1000+ students. Building full-stack educational platform.</text>
<circle cx="100" cy="170" r="6" fill="#6366F1"/>
<text x="120" y="174" fill="#fff" font-family="system-ui, sans-serif" font-size="14" font-weight="600">App Developer \u2014 Hack Club</text>
<text x="120" y="192" fill="#888" font-family="system-ui, sans-serif" font-size="12">2024 \u2014 Present</text>
<text x="120" y="212" fill="#666" font-family="system-ui, sans-serif" font-size="12">Developing apps and contributing to the Hack Club community.</text>
<circle cx="100" cy="250" r="6" fill="#22D3EE"/>
<text x="120" y="254" fill="#fff" font-family="system-ui, sans-serif" font-size="14" font-weight="600">Open Source Developer</text>
<text x="120" y="272" fill="#888" font-family="system-ui, sans-serif" font-size="12">2024 \u2014 Present</text>
<text x="120" y="292" fill="#666" font-family="system-ui, sans-serif" font-size="12">Creating React hooks, Tailwind plugins, Vite plugins, and CLI tools.</text>
<circle cx="100" cy="330" r="6" fill="#D946EF"/>
<text x="120" y="334" fill="#fff" font-family="system-ui, sans-serif" font-size="14" font-weight="600">Student \u2014 Toronto, Canada</text>
<text x="120" y="352" fill="#888" font-family="system-ui, sans-serif" font-size="12">Ongoing</text>
<text x="120" y="372" fill="#666" font-family="system-ui, sans-serif" font-size="12">Full-Stack &amp; Spatial Computing focus. Building HELIOS spatial OS.</text>
</svg>'''

write_svg('experience.svg', exp_svg)
PYEOF

  cd "$PROFILE_REPO_DIR"
  if git diff --quiet -- '*.svg'; then
    log "No SVG changes needed."
  else
    git add '*.svg' images/ 2>/dev/null || true
    git diff --staged --quiet || (git commit -m "Update profile SVGs [skip ci]" && git push origin HEAD 2>&1 | tee -a "$LOG_FILE")
    log "SVGs updated and pushed."
  fi

  cd "$PIPELINE_DIR"
}

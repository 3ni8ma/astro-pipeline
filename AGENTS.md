# Daily Contribution Pipeline

## How to run manually
Send: `Run the daily contribution pipeline`

This triggers the full pipeline: stat refresh, README update, SVG generation, workflow triggers, and 5-10 contributions across all repos.

## What it does
| Step | Action |
|------|--------|
| 1 | Fetches live GitHub stats (stars, contributions, streak) |
| 2 | Updates profile README badges with real numbers |
| 3 | Regenerates radar.svg, about.svg, header.svg, experience.svg |
| 4 | Triggers snake.yml and profile-3d.yml workflows |
| 5 | Makes 5-10 contributions across personal repos |
| 6 | Posts devlog to Stardance (project 5983, Frictionless goal — 5h min) |
| 7 | Searches for good-first-issues on popular repos |

## Repos maintained
- `3ni8ma/3ni8ma` — Profile README + SVGs
- `3ni8ma/react-hooks` — React hooks library
- `3ni8ma/tailwind-plugin` — Tailwind CSS utilities
- `3ni8ma/vite-plugin` — Vite sitemap plugin
- `3ni8ma/cli-tool` — CLI scaffolding tool
- `3ni8ma/aarushkarak-website` — Portfolio site
- `3ni8ma/TheCoderBros-Website` — Educational platform

## Notes
- Git commits use the configured email for contribution graph credit
- Pipeline runs from `pipeline.sh`
- A cron job runs every 30 minutes
- Logs are at `pipeline.log`

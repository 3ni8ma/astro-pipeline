#!/usr/bin/env bash
set -euo pipefail

# Astro Pipeline — VM Setup Script
# Run this on a fresh Ubuntu 24.04 Oracle Cloud VM.
# After running, place your .stardance_cookie in /home/ubuntu/.stardance_cookie

echo "=== Installing dependencies ==="
sudo apt update -qq
sudo apt install -y -qq curl git python3 jq

echo "=== Cloning astro-pipeline ==="
cd /home/ubuntu
if [ -d astro-pipeline ]; then
  cd astro-pipeline && git pull
else
  git clone https://github.com/3ni8ma/astro-pipeline.git
fi

echo "=== Setting up WakaTime config ==="
echo ""
echo "Enter your WAKATIME_API_KEY (from ~/.wakatime.cfg on your local machine):"
read -r waka_key
echo "Enter your WAKATIME_API_URL (default: https://hackatime.hackclub.com/api/hackatime/v1):"
read -r waka_url
waka_url="${waka_url:-https://hackatime.hackclub.com/api/hackatime/v1}"

cat > /home/ubuntu/.wakatime.cfg << CFGEOF
[settings]
api_key = ${waka_key}
api_url = ${waka_url}
debug = false
CFGEOF
chmod 600 /home/ubuntu/.wakatime.cfg

echo "=== Setting up Stardance cookie ==="
echo ""
echo "IMPORTANT: Place your Stardance session cookie at /home/ubuntu/.stardance_cookie"
echo "Get it from your local machine:"
echo "  cat pipeline/.stardance_cookie"
echo ""
echo "Format (one line):"
echo "  _stardance_session_v3=<value>; _stardance_session_v2=<value>"
echo ""

read -p "Have you copied .stardance_cookie to this VM? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  chmod 600 /home/ubuntu/.stardance_cookie
  echo "Cookie set."
else
  echo "You can place it later with:"
  echo "  scp .stardance_cookie ubuntu@<VM_IP>:/home/ubuntu/.stardance_cookie"
fi

echo "=== Setting up systemd service ==="
sudo cp /home/ubuntu/astro-pipeline/vm/astro-daemon.service /etc/systemd/system/
sudo cp /home/ubuntu/astro-pipeline/vm/astro-daemon.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable astro-daemon.timer
sudo systemctl start astro-daemon.timer

echo "=== Status ==="
sudo systemctl status astro-daemon.timer --no-pager
echo ""
echo "Setup complete! The daemon will run every 30 min via systemd timer."
echo "Logs: journalctl -u astro-daemon.service -f"
echo "Test immediately: sudo systemctl start astro-daemon.service"

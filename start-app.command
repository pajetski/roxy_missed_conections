#!/bin/bash
# Roxy Missed Connections — Local Server Launcher
# Double-click this file in Finder to start the app

cd "$(dirname "$0")"

# Kill any existing server on port 3000
lsof -ti:3000 | xargs kill -9 2>/dev/null

echo "Starting Roxy Missed Connections..."
echo "Opening http://localhost:3000 in Chrome..."

# Open Chrome after a short delay
sleep 1 && open -a "Google Chrome" "http://localhost:3000" &

# Start Python server
python3 -m http.server 3000

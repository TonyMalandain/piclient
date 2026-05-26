#!/bin/bash

# Serve setup.sh locally for testing on a Pi without pushing to GitHub.
# Run this on your dev machine, then use the printed curl command on the Pi.

PORT=${1:-8080}
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve local IP (first non-loopback address)
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(hostname -I | awk '{print $1}')
fi

echo ""
echo "🖥️  Serving $(basename "$DIR") from $DIR"
echo ""
echo "   Run this on the Pi to test:"
echo ""
echo "   curl -sSL http://$LOCAL_IP:$PORT/setup.sh | sudo bash -s -- <REMOTE_IP> <USERNAME> <PASSWORD>"
echo ""
echo "   Ctrl+C to stop."
echo ""

cd "$DIR"
python3 -m http.server "$PORT"

#!/bin/bash
# Remove the librecontrol-stack launchd supervisor.
set -euo pipefail
LA="$HOME/Library/LaunchAgents"
DOM="gui/$(id -u)"
for svc in com.librecontrol.daphne com.librecontrol.bot com.librecontrol.daemon; do
  launchctl bootout "$DOM/$svc" 2>/dev/null || true
  rm -f "$LA/$svc.plist"
  echo "removed: $svc"
done

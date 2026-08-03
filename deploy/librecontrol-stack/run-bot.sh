#!/bin/bash
# Supervised inbound Telegram bot (single getUpdates consumer). Restarted by launchd.
# CRITICAL: exactly one instance — two consumers steal each other's updates.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/librecontrol-stack.env"
export PATH="$LCTL_PATH_EXTRA:$PATH"
cd "$LCTL_REPO/backend"
exec "$LCTL_REPO/backend/.venv/bin/python" manage.py run_telegram_bot

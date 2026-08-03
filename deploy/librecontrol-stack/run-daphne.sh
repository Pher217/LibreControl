#!/bin/bash
# Supervised backend (ASGI: HTTP + websockets). Restarted by launchd KeepAlive.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/librecontrol-stack.env"
export PATH="$LCTL_PATH_EXTRA:$PATH"
cd "$LCTL_REPO/backend"
exec "$LCTL_REPO/backend/.venv/bin/daphne" -b "${LCTL_BIND_HOST:-127.0.0.1}" -p 8000 config.asgi:application

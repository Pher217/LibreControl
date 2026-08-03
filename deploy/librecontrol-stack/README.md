# librecontrol-stack — launchd supervisor (macOS)

Keeps the LibreControl reverse-input stack alive so it is **not "broken
every morning"**. The three processes are hand-startable but had no supervisor;
launchd `KeepAlive` restarts them on crash and `RunAtLoad` starts them at login.

## Processes
| Service | What | Wrapper |
|---|---|---|
| `com.librecontrol.daphne` | backend ASGI (HTTP + ws) on :8000 | `run-daphne.sh` |
| `com.librecontrol.bot` | inbound Telegram bot (single getUpdates consumer) | `run-bot.sh` |
| `com.librecontrol.daemon` | host-agent daemon (headless.prompt / pty.inject recv loop) | `run-daemon.sh` |

All config (paths, `LCTL_HEADLESS_ENGINE`, `OBSERVE_DELIVERY_MODE`)
lives in `librecontrol-stack.env` — the single source of truth.

## Use
```bash
deploy/librecontrol-stack/install.sh     # install + start (idempotent; kills hand-started dupes first)
deploy/librecontrol-stack/status.sh      # state + pids + backend probe + one-bot check
deploy/librecontrol-stack/uninstall.sh   # stop + remove
# after editing librecontrol-stack.env or pulling code:
launchctl kickstart -k gui/$(id -u)/com.librecontrol.daemon   # restart one service
```
Logs: `~/Library/Logs/librecontrol-stack/{daphne,bot,daemon}.log`.

## Rollback the driving engine
`LCTL_HEADLESS_ENGINE=interactive` (default) is the recommended default: one
persistent `claude` stream-json process per session, no per-tool gate,
trusted-host mode. Set `LCTL_HEADLESS_ENGINE=sdk` for the Agent-SDK path with
per-tool Allow/Deny approval buttons. Unset it in `librecontrol-stack.env` to fall back
to the legacy `claude -p` path. Kickstart the daemon after.

## Not covered (follow-ups)
- Windows supervisor (Task Scheduler / NSSM) — see the cross-platform spec.
- Postgres/redis are assumed already running (Homebrew services).

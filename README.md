# LibreControl

[![CI](https://github.com/Pher217/LibreControl/actions/workflows/ci.yml/badge.svg)](https://github.com/Pher217/LibreControl/actions/workflows/ci.yml) [![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE) [![Self-hosted](https://img.shields.io/badge/self--hosted-sovereign-6f42c1)](#why-its-different) [![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md) [![GitHub stars](https://img.shields.io/github/stars/Pher217/LibreControl?style=social)](https://github.com/Pher217/LibreControl/stargazers)

> One universal /remote-control for every coding agent you run — Claude Code, Codex, Gemini, Cursor, Copilot, and any MCP tool, across all your machines — centralized into the single chat app you choose (Telegram, WhatsApp, Slack, Signal, Discord…). Start, watch, and drive any session from your phone.

AI agents now run everywhere: laptops, VPSes, workstations, terminals, editors, MCP tools. The hard part isn't starting them — it's noticing when one needs you. An agent can sit paused on a yes/no in a tmux pane you closed hours ago, while you're nowhere near that keyboard. The deeper problem is that these agents are scattered across machines, terminals, editors and tools with no single place to see or answer them. LibreControl is that single place.

## Demo

![One Telegram chat, every agent, every machine](docs/screenshots/telegram-fleet.png)

One Telegram group, one topic per session — Claude and Codex, running on a MacBook and a Windows box, streaming and driveable side by side. Approvals and questions (`request_approval`, `ask_human`) land right in the topic.

<!-- Record a 20-40s screen capture: type in Claude Code -> it appears in your Telegram group -> reply from your phone -> it drives the session. Save it as docs/demo.gif, then uncomment the line below. -->

<!-- ![Drive a Claude Code session from your phone](docs/demo.gif) -->

> 🎥 **Animated demo coming soon** — a ~20-second clip: start a Claude Code session, then drive it from your phone.

Agents **notify** you, **ask** you questions, and **request approval** — so you **start**, **stream**, **drive**, answer and approve every one of them in one place, without hunting down the right machine, terminal, or editor.

It's sovereign by design: you host it, your sessions and credentials never leave your infrastructure, and it reaches your tools through official SDKs and the open Model Context Protocol — never browser scraping or vendor hacks.

## How it compares

The nearby tools solve a narrower problem. **If you only ever run Claude Code on one machine, use Claude Code Channels** — it's official, free, and needs no setup. LibreControl exists for the case it doesn't cover: several different agents, several machines, and infrastructure you control.

| | Claude Code Channels | OpenClaw | **LibreControl** |
|---|---|---|---|
| **Agents** | Claude Code only | its own agent | Claude Code, Codex, Gemini, Cursor, Copilot — any MCP tool |
| **Machines** | the session in front of you | single host | a **fleet** — laptop + workstation + VPS, one inbox |
| **Hosting** | vendor-operated | — | **fully self-hosted** — sessions, prompts and credentials stay on your hardware |
| **Chat surfaces** | Telegram, Discord, iMessage | WhatsApp, Telegram, Discord, Slack | Telegram today; WhatsApp / Slack / Discord / Signal / iMessage via the gateway |
| **Shape** | a remote for one live session | an autonomous 24/7 agent | supervise **many** live sessions — stream, drive, approve |
| **Approvals + audit** | — | — | risk-tiered approvals (fail-closed), append-only Postgres audit log |
| **Setup** | zero | moderate | Docker + a Telegram bot token |

The trade is deliberate: you spend a few minutes standing up a backend, and in exchange nothing about your sessions leaves hardware you own — and one inbox covers every agent on every machine you run.

## How it works

```
   Coding agents & machines              LibreControl             Your app of choice
 ─────────────────────────────       ─────────────────────       ─────────────────────
 Claude Code / Codex / Cursor …                                  Telegram
   /librecontrol            ──▶                                  WhatsApp / Slack /
 host-agent (each machine)  ──▶  ──▶  one chat session per  ◀─▶  Discord / Signal /
 drive + mirror             ──▶       agent · policy ·            iMessage
   via librecontrol-mcp dispatch     approvals · audit
```

You live in **one app you already use** — Telegram, or WhatsApp / Slack / Signal through  bridges. There is no separate inbox to learn. From inside the coding agent you're already working in (Claude Code, Codex, Cursor, …), run the universal command to **dispatch that session to your phone**:

```
/librecontrol [name]
```

It starts a named session and pushes it out to your app of choice; from then on the agent's `notify` / `ask` / `approve` calls land there and you supervise from anywhere. Under the hood the command is the `librecontrol` tool on the `librecontrol-mcp` bridge, so it works from *any* MCP-capable tool — a ready-made [`/librecontrol` Claude Code command](connectors/librecontrol-mcp/claude/librecontrol.md) ships with the bridge.

Agents reach that same chat two ways:

1. **Chat topics** — sessions are dispatched to a chat topic that both streams the turns and accepts input that drives the session ([PR #90](https://github.com/Pher217/LibreControl/pull/90)).
2. **The universal MCP bridge (`librecontrol-mcp`)** — a small MCP server you install into *any* MCP-capable tool (Cursor, Copilot, Codex, Claude Code, Kiro, …). It is purely a **dispatch tool**: the agent gains four calls that route through *your* backend into the same chat —
   - `librecontrol(name)` — start a session and dispatch it to your chat app
   - `notify(message)` — push progress to your chat
   - `ask_human(question, options)` — ask you something and wait for the reply
   - `request_approval(action, preview)` — request permission for an action (**fail-closed**: denies on timeout)

   This is opt-in and agent-initiated — the agent calls out to you. No vendor API is impersonated, no closed UI is driven.

## Repository layout

```
backend/              Django + DRF + Channels control plane (ASGI)
  apps/
    accounts hosts projects     fleet inventory: agent accounts, machines, projects
    threads prompts approvals    session primitives: conversations, answer-in-chat, gated actions
    observe                      turn persistence + chat delivery for driven sessions (the multi-runtime read-only watcher was removed — see PR #90)
    hostlink                     host-daemon enrollment + PTY/command WebSocket consumer
    connectors gateway           universal MCP bridge backend + messaging-gateway backend
    telegram slash supervisor    Telegram surface, slash commands, fleet-aware digest
    policies audit tier2 skills   guardrails, append-only audit log, local chat model, skill registry
  config/                        settings, ASGI/WSGI, Channels routing, Celery
host-agent/           Python daemon per machine: enrollment, PTY streaming, input-safety policy
connectors/
  librecontrol-mcp/   installable MCP bridge client (librecontrol / notify / ask_human / request_approval)
  messaging-gateway/  Node/TS sidecar bridging WhatsApp / Slack / Discord / Signal / iMessage
deploy/               Docker Compose, Caddy, and headscale deployment configs
```

## Status — write+stream driving is live

The backend and host-agent daemon are implemented and tested: **~1,000 tests passing** (727 backend, 270 host-agent), live ASGI smoke test green.

**Shipped:**

- Session dispatch to a **Telegram forum topic** via the universal **`/librecontrol`** command (the `librecontrol` librecontrol-mcp tool + a shipped Claude Code command)
- **Bind-to-calling-session** — driving *this* Claude Code session from chat via `CLAUDE_CODE_SESSION_ID` ([PR #91](https://github.com/Pher217/LibreControl/pull/91))
- **A scoped editor-turn mirror** with drive suppression, so typed-in-editor turns and chat-driven turns never double-post ([PR #93](https://github.com/Pher217/LibreControl/pull/93), [PR #94](https://github.com/Pher217/LibreControl/pull/94))
- **A persistent interactive engine** (`LCTL_HEADLESS_ENGINE=interactive`) — one long-lived `claude -p` stream-json process per session, warm multi-turn replies, and restart survival ([PR #95](https://github.com/Pher217/LibreControl/pull/95), [PR #96](https://github.com/Pher217/LibreControl/pull/96))
- **A bot liveness watchdog** so a stuck Telegram `getUpdates` consumer is caught and restarted ([PR #97](https://github.com/Pher217/LibreControl/pull/97))
- **The universal MCP bridge** — `apps.connectors` backend + the installable [`librecontrol-mcp`](connectors/librecontrol-mcp/README.md) client
- **Telegram** surface + the **messaging-gateway** connector (→ WhatsApp / Slack / Discord / Signal / iMessage)
- **Multi-host** backend (`apps.hostlink`) + a **host daemon client** (`host-agent`: `librectl enroll | daemon`)
- **A PTY input-safety core** that the next milestone builds on

**In progress / next:**

- A **deploy runbook** (docker-compose: backend + messaging-gateway sidecar + headscale; daemon on a second machine)
- `librectl run` — approval-gated remote terminal (PTY) streaming, building on the existing input-safety core
- Per-connector keypair identity hardening (replacing the shared bearer token) before any multi-user use

## Why it's different

- **One place for everything** — every agent, every machine, every tool, funnelled into a single chat inbox you already live in. No new app, no per-tool dashboards, no context-switching.
- **Sovereign / self-hosted** — no SaaS, no hosted middleman. Sessions, prompts, approvals, and credentials stay on hardware you own. The whole stack is OSS and self-hostable.
- **Multi-host** — your MacBook, Windows workstation, and Linux VPS become one fleet, one inbox. A host daemon enrolls each machine over your private network.
- **Multi-runtime** — Claude Code today (dispatch, mirror, drive); other MCP-capable tools connect via the `librecontrol-mcp` bridge; per-provider drive engines are on the roadmap.
- **Two-way, not just a viewer** — agents ask, you answer; agents request, you approve — right from chat.
- **Policy + approval + audit built in** — sensitivity-aware project profiles, risk-tiered approvals, and an append-only Postgres audit log across heterogeneous runtimes.
- **Surfaces you already use** — Telegram today; the messaging-gateway connector fans out to WhatsApp, Slack, Discord, Signal, and iMessage.

## What it is not

- a new AI agent
- a replacement for Claude Code, Codex, Gemini, Cursor, or Copilot
- a hosted SaaS, a workflow builder, or an IDE
- a browser-scraping wrapper around closed vendor UIs

If a tool can't be reached through an SDK, exported session files, or MCP, it stays out of scope — no brittle browser hacks.

## Try the bridge

The fastest way to see this work: connect one tool and have its agent send a notification or ask a question through your chat inbox. With a backend running, install [`librecontrol-mcp`](connectors/librecontrol-mcp/README.md) into any MCP tool:

```bash
# Claude Code
claude mcp add librecontrol -- librecontrol-mcp
```

```toml
# OpenAI Codex CLI — ~/.codex/config.toml
[mcp_servers.librecontrol]
command = "librecontrol-mcp"
```

```json
// Cursor — ~/.cursor/mcp.json
{ "mcpServers": { "librecontrol": { "command": "librecontrol-mcp" } } }
```

Set `LCTL_BACKEND_URL` and `LCTL_CONNECTOR_TOKEN`, and the agent can reach your chat. Full env reference and the other tools are in the [`librecontrol-mcp` README](connectors/librecontrol-mcp/README.md).

## Quick start (Docker)

The fastest way to a working setup — one command brings up the whole stack (backend, Postgres, Valkey, Telegram bot) and enrolls this machine's host daemon:

```bash
./quickstart.sh
```

You'll need three things it can't do for you: Docker installed, [`uv`](https://docs.astral.sh/uv/getting-started/installation/), a Telegram bot token from [@BotFather](https://t.me/BotFather), and a Telegram group with Topics enabled (add your bot as admin). The script generates all secrets, validates your token, auto-discovers your chat, starts the stack, then installs and enrolls this machine's host daemon.

If enrollment doesn't complete, the script says so explicitly and prints the commands to finish — it will not report success without an enrolled daemon, because `/librecontrol` cannot work until the daemon is running. Start it with the command the script prints, then run `/librecontrol` in Claude Code. See [deploy/README.md](deploy/README.md) for the manual/production path, and [Troubleshooting](#troubleshooting) if something stalls.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Telegram chat auto-discovery timed out during `quickstart.sh` | The allowlist is left empty and the default-deny policy drops everything | Set `TELEGRAM_ALLOWED_CHAT_IDS`, `TELEGRAM_FORUM_CHAT_ID`, and `LCTL_PROMPT_CHAT_ID` in `deploy/.env`, then `docker compose --env-file deploy/.env -f deploy/app/docker-compose.yml up -d` to restart with the new values |
| Backend health check never goes green | The `web` container is failing to start or migrate | `docker compose -f deploy/app/docker-compose.yml logs web` |
| "This session doesn't accept typed input" in Telegram | The thread is not a driveable session — chat is mirror-only for that thread | Start a driveable session with `/librecontrol` in Claude Code first, then reply in its topic |
| Bot receives nothing / input is silently ignored | Two `run_telegram_bot` processes are running and stealing each other's `getUpdates` | Confirm exactly one is running, e.g. `docker compose -f deploy/app/docker-compose.yml ps telegram-bot`, and make sure no local `python manage.py run_telegram_bot` is also running |
| Port already in use (8000 / 5432 / 5544) | Another process is bound to the backend (`8000`) or a local dev Postgres (`5544`→`5432`) | `lsof -i :8000` / `lsof -i :5544`, stop the conflicting process, or change the port mapping before bringing the stack up |
| `/librecontrol` never dispatches — the host daemon was never installed | This is the most common gap after `quickstart.sh`: the backend is up but this machine isn't enrolled | `cd host-agent && uv sync && .venv/bin/librectl enroll --backend <BACKEND_URL> --secret "$LCTL_ENROLL_SECRET"`, then `LCTL_HEADLESS_ENGINE=interactive .venv/bin/librectl daemon` |

## Run the backend (dev)

```bash
# Postgres for tests / dev
docker run -d --name librecontrol-pg \
  -e POSTGRES_DB=librecontrol -e POSTGRES_USER=acc_user \
  -e POSTGRES_PASSWORD=acc_password -p 5544:5432 postgres:16

cd backend
uv sync --extra dev
POSTGRES_PORT=5544 POSTGRES_HOST=localhost .venv/bin/python -m pytest -q
```

> **Note:** `acc_user` / `acc_password` are throwaway local-dev credentials — they are **not** production secrets. Set a real `POSTGRES_PASSWORD` (and `SECRET_KEY`) via the environment before deploying.

See [`docker-compose.yml`](docker-compose.yml) and the [`Makefile`](Makefile) for the full dev loop.

## Stack

All free / OSS-friendly:

- **Backend** — Django 5.2, DRF, Channels, Celery 5
- **Data plane** — PostgreSQL 16, Valkey 8, append-only audit log
- **Surfaces** — Telegram; WhatsApp / Slack / Discord / Signal / iMessage via the messaging-gateway connector; MCP bridge for coding agents
- **Host side** — Python 3.13 daemon, Tailscale connectivity; headscale is an optional deploy path (`deploy/headscale/`); age-encrypted credential vault, ntfy push, and faster-whisper voice are planned
- **Ops** — Docker Compose (dev), Caddy 2, OpenTelemetry → Loki + Tempo + Prometheus + Grafana

## Contributing

The backend foundation is solid; the most useful contributions right now are about **reaching more tools and standing it up live**. Best first contributions:

- **Add a per-provider drive engine or chat surface.** Contributions are wanted for per-provider drive engines and chat surfaces; open a discussion describing the tool's session lifecycle, auth modes, and the events/hooks it exposes.
- **Test the deploy path** on your own self-hosted infrastructure and report where the docs fall short — the runbook is being written now, and real-world friction is invaluable.
- **Improve the `librecontrol-mcp` install docs** for Cursor, Codex, Claude Code, Copilot, and Kiro.
- **Harden the security boundaries** — the vault, policy engine, secrets redactor, and approval flow get design review before changes; security-minded eyes are very welcome. See [SECURITY.md](SECURITY.md) and [`docs/security/`](docs/security/).
- **Bug reports and tests** against the existing backend apps.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow, CI, and commit conventions. Some early design notes still live in the maintainer's private knowledge base; if a decision is unclear, open an issue and we'll move the needed context into public docs.

## License

[Apache-2.0](LICENSE) for code. Documentation in [`docs/`](docs/) is dual-licensed CC-BY-SA 4.0 / Apache-2.0.

LibreControl is an independent, third-party project, not affiliated with Anthropic, OpenAI, Google, or other supported tool vendors. Per Anthropic's Agent SDK guidelines it does not use the "Claude Code" name or visual style; in the UI, Claude runtimes are labeled "Claude Agent (SDK)", "Claude (Remote Control)", "Claude (CLI)", or "Claude (observed)" depending on the adapter.

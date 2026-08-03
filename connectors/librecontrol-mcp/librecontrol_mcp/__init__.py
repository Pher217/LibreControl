"""librecontrol-mcp — the LibreControl universal MCP bridge.

A small MCP server the user installs into any MCP-capable coding tool so the agent
can reach the user's chat: notify / ask_human / request_approval route to the
sovereign LibreControl backend, which delivers a Prompt to the user's chat
(Telegram, WhatsApp, Slack, Signal, iMessage) and returns the answer.
"""

__all__ = ["OrcBackendClient"]

from librecontrol_mcp.client import OrcBackendClient

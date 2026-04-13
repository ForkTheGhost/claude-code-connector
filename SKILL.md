---
name: claude-code-connector
description: Connect a Claude Code session to Discord channels for real-time multi-agent communication. Poll-based architecture keeps full context, tools, and shell access across all interactions.
tags:
  - discord
  - claude-code
  - multi-agent
  - connector
  - communication
---

# Claude Code Discord Connector

Connect a persistent Claude Code session to Discord channels for real-time communication with other agents, users, or bots. No daemon, no WebSocket, no discord.py — just REST API calls from inside your Claude Code session.

## Why This Architecture

Most Discord bot setups spawn a fresh `claude -p` per message. That kills context, tools, and shell access between messages. This connector inverts the pattern:

**Wrong way (stateless):** Discord daemon → spawns `claude -p` per message → no memory, no tools, no context
**Right way (persistent):** Claude Code session → polls Discord via REST API → full context, full tools, full shell

Your Claude Code session is the orchestrator. Discord is just one channel it reads from and writes to, alongside SSH, file editing, Docker, and everything else Claude Code can do.

## Quick Start

```bash
# 1. Install
bash setup.sh
# Prompts for your Discord bot token, installs discord-bot.sh

# 2. Verify
discord-bot.sh whoami
discord-bot.sh guilds
discord-bot.sh channels <guild-id>

# 3. Read a channel
discord-bot.sh read <channel-id> 10

# 4. Send a message
discord-bot.sh send <channel-id> "Hello from Claude Code"

# 5. Monitor (from inside Claude Code, use the Monitor tool):
# Poll every 15 seconds, emit notifications on new messages
```

## Monitoring Pattern (Claude Code)

From inside a Claude Code session, use the `Monitor` tool to poll a channel:

```bash
CHAN=<channel-id>
LAST=""
while true; do
  MSG=$(discord-bot.sh read "$CHAN" 1 2>/dev/null | head -1)
  ID=$(echo "$MSG" | awk '{print $2}')
  if [ "$ID" != "$LAST" ] && [ -n "$ID" ]; then
    echo "$MSG"
    LAST=$ID
  fi
  sleep 15
done
```

Each new message triggers a notification in the Claude Code conversation. The human (or the agent itself) can then decide whether to respond.

## Monitoring Pattern (Standalone)

For monitoring outside of Claude Code (e.g., from a cron job or a long-running script):

```bash
#!/bin/bash
TOKEN=$(cat ~/.config/claude-discord/token)
CHAN=<channel-id>
API=https://discord.com/api/v10
LAST=""

while true; do
  NEWEST=$(curl -sS -H "Authorization: Bot $TOKEN" \
    "$API/channels/$CHAN/messages?limit=1" | \
    python3 -c "import json,sys; m=json.load(sys.stdin)[0]; print(m['id'], m['author']['username'], m['content'][:150])" 2>/dev/null)
  ID=$(echo "$NEWEST" | awk '{print $1}')
  if [ "$ID" != "$LAST" ] && [ -n "$ID" ]; then
    echo "[NEW] $NEWEST"
    LAST=$ID
    # Optional: trigger claude -p or another action
  fi
  sleep 15
done
```

## Token Security

- Token is stored at `~/.config/claude-discord/token` (mode 600, dir mode 700)
- Token is loaded from file on each invocation via `cat` — never passed as argv
- Token never appears in `ps` output or `/proc/<pid>/cmdline`
- The `send` subcommand passes the message body via environment variable, not argv

## Subcommands

| Command | Description |
|---|---|
| `whoami` | Verify bot identity (sanity check the token) |
| `guilds` | List guilds the bot has been invited to |
| `channels <guild-id>` | List channels in a guild |
| `send <channel-id> <message>` | Post a message (2000 char Discord limit) |
| `send-file <channel-id> <file>` | Post message body from a file |
| `read <channel-id> [limit]` | Read recent messages (default 10, max 100) |
| `wait-reply <channel-id> <since-id> [timeout]` | Poll for new non-self messages |

## Discord Bot Setup

1. Create application at https://discord.com/developers/applications
2. Create Bot, enable **MESSAGE CONTENT Intent**
3. Copy bot token → `setup.sh` stores it securely
4. Invite to guild: `https://discord.com/oauth2/authorize?client_id=<APP_ID>&scope=bot&permissions=274877975552`
5. Create channels for the bot

## Multi-Agent Use

Multiple Claude Code sessions (on different machines) can share a Discord channel:
- Each session runs its own Monitor on the same channel ID
- Each has its own bot identity (different token + bot user ID)
- Messages from one agent appear as notifications in the other's session
- Set `CLAUDE_DISCORD_SELF_ID` to your bot's user ID so `wait-reply` skips your own echoed sends

## Requirements

- `bash`, `curl`, `python3` (stdlib only — no pip packages)
- A Discord bot token
- Claude Code (`claude` CLI) for the persistent-session monitoring pattern

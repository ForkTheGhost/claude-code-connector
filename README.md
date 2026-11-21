---
description: Claude Code Discord Connector — REST API wrapper + polling pattern for persistent multi-agent communication
tags:
  - discord
  - claude-code
  - connector
  - multi-agent
---

# Claude Code Discord Connector

A Discord bridge for persistent Claude Code sessions that need their tools, context and multi-agent continuity.

## The problem

The usual way to put an agent on Discord is a bot or webhook that starts a fresh `claude -p` for every message. Each message then begins with no memory, no open files and no shell state. This connector flips that around: your long-running Claude Code session polls Discord over plain REST, so it keeps its full context, tools and shell between messages.

## When to use this instead of a normal Discord bot, webhook or chat bridge

- You want one Claude Code session to stay connected to Discord without losing its shell and tool context.
- You run several long-lived agents that coordinate through shared channels and need continuity across hours or days.
- You prefer polling plus REST (a shell script and a bot token) over a daemon, a WebSocket gateway or `discord.py`.
- You want remote coordination without rebuilding your agent workflow around Discord. Discord stays one channel the session reads and writes, next to SSH, editing and Docker.

If you only need to post one-way notifications, a plain webhook is simpler.

See [SKILL.md](SKILL.md) for full documentation, setup, and usage patterns.

## Quick Start

```bash
bash setup.sh          # install + configure token
discord-bot.sh whoami  # verify
discord-bot.sh read <channel-id>  # read messages
discord-bot.sh send <channel-id> "Hello"  # send
```

## Files

- `discord-bot.sh` — REST API wrapper (read/send/channels/guilds/wait-reply)
- `setup.sh` — interactive setup (token, install, verify)
- `SKILL.md` — full documentation + monitoring patterns

## License

Apache 2.0

## Contributing

### Issues

All features and bug reports must be tracked as GitHub Issues before any work begins. Issues are the authoritative record of intent — PRs without a corresponding issue will not be merged.

### Pull Requests

All changes require a PR. Direct commits to the default branch are not permitted.

**PR requirements:**
- Reference the issue in the PR description (`Closes #N` or `Ref #N`)
- Include a `CHANGELOG.md` entry — one entry per issue, referencing the issue number for full context
- All code review comments must be acknowledged and addressed before merge — no unresolved items at merge time

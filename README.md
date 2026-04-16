---
description: Claude Code Discord Connector — REST API wrapper + polling pattern for persistent multi-agent communication
tags:
  - discord
  - claude-code
  - connector
  - multi-agent
---

# Claude Code Discord Connector

Connect Claude Code sessions to Discord for real-time multi-agent communication without losing context, tools, or shell access.

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

#!/bin/bash
#
# discord-bot.sh — thin wrapper around the Discord REST API for
# Claude Code sessions. Loads the bot token from a file on every
# invocation so the token never appears in command-line arguments
# or process lists.
#
# Usage:
#   discord-bot.sh whoami
#     Fetch the bot's own identity (sanity check the token).
#
#   discord-bot.sh guilds
#     List guilds the bot has been invited to.
#
#   discord-bot.sh channels <guild-id>
#     List channels in a guild the bot can see.
#
#   discord-bot.sh send <channel-id> <message...>
#     Post a plain message to a channel.
#
#   discord-bot.sh send-file <channel-id> <file-with-message-body>
#     Post a message whose body is read from a file (avoids shell
#     quoting hell for long multi-line prompts).
#
#   discord-bot.sh read <channel-id> [limit]
#     Fetch the most recent messages from a channel, newest first.
#     Default limit 10, max 100.
#
#   discord-bot.sh wait-reply <channel-id> <since-message-id> [timeout-sec]
#     Poll the channel until a new message from a non-self author
#     appears after <since-message-id>, or until the timeout.
#     Prints the first matching message's content to stdout and its
#     id to stderr. Default timeout 120 s, poll interval 2 s.
#
# Setup:
#   1. Create a Discord bot at https://discord.com/developers/applications
#   2. Copy the bot token
#   3. mkdir -p ~/.config/claude-discord && chmod 700 ~/.config/claude-discord
#   4. echo "<your-bot-token>" > ~/.config/claude-discord/token
#   5. chmod 600 ~/.config/claude-discord/token
#   6. Invite bot to your guild:
#      https://discord.com/oauth2/authorize?client_id=<APP_ID>&scope=bot&permissions=274877975552
#
# Environment variables (optional):
#   CLAUDE_DISCORD_TOKEN_FILE  Override token file path
#   CLAUDE_DISCORD_SELF_ID     Your bot's user ID (used by wait-reply to skip echoed sends)

set -eu
API=https://discord.com/api/v10
TOKEN_FILE="${CLAUDE_DISCORD_TOKEN_FILE:-$HOME/.config/claude-discord/token}"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "discord-bot: token file not found at $TOKEN_FILE" >&2
  echo "  Create one: echo '<your-bot-token>' > $TOKEN_FILE && chmod 600 $TOKEN_FILE" >&2
  exit 2
fi
TOKEN="$(cat "$TOKEN_FILE")"
if [ -z "$TOKEN" ]; then
  echo "discord-bot: token file is empty" >&2
  exit 2
fi
HEAD=(-H "Authorization: Bot $TOKEN" -H "Content-Type: application/json" -H "User-Agent: ClaudeCodeConnector/1.0")

SELF_BOT_ID="${CLAUDE_DISCORD_SELF_ID:-}"

cmd="${1:-}"
shift || true

case "$cmd" in
  whoami)
    curl -sS --max-time 10 "${HEAD[@]}" "$API/users/@me"
    echo
    ;;

  guilds)
    curl -sS --max-time 10 "${HEAD[@]}" "$API/users/@me/guilds" \
      | python3 -c 'import json,sys; [print(g["id"], g["name"]) for g in json.load(sys.stdin)]'
    ;;

  channels)
    GUILD="${1:?usage: channels <guild-id>}"
    curl -sS --max-time 10 "${HEAD[@]}" "$API/guilds/$GUILD/channels" \
      | python3 -c 'import json,sys; [print(c["id"], c.get("type"), "#"+c.get("name","?")) for c in json.load(sys.stdin)]'
    ;;

  send)
    CHAN="${1:?usage: send <channel-id> <message...>}"
    shift
    BODY="$*"
    export BODY TOKEN_FILE CHAN API
    python3 -c '
import json, os, urllib.request
api = os.environ["API"]
chan = os.environ["CHAN"]
url = api + "/channels/" + chan + "/messages"
token = open(os.environ["TOKEN_FILE"]).read().strip()
body = json.dumps({"content": os.environ["BODY"]}).encode()
req = urllib.request.Request(
    url,
    data=body,
    method="POST",
    headers={
        "Authorization": "Bot " + token,
        "Content-Type": "application/json",
        "User-Agent": "ClaudeCodeConnector",
    },
)
with urllib.request.urlopen(req, timeout=15) as r:
    d = json.load(r)
print(d["id"], d["channel_id"])
'
    ;;

  send-file)
    CHAN="${1:?usage: send-file <channel-id> <file>}"
    FILE="${2:?usage: send-file <channel-id> <file>}"
    if [ ! -r "$FILE" ]; then
      echo "discord-bot: cannot read $FILE" >&2
      exit 2
    fi
    BODY=$(cat "$FILE")
    export BODY TOKEN_FILE CHAN API
    python3 -c '
import json, os, urllib.request
api = os.environ["API"]
chan = os.environ["CHAN"]
url = api + "/channels/" + chan + "/messages"
token = open(os.environ["TOKEN_FILE"]).read().strip()
body = json.dumps({"content": os.environ["BODY"]}).encode()
req = urllib.request.Request(
    url,
    data=body,
    method="POST",
    headers={
        "Authorization": "Bot " + token,
        "Content-Type": "application/json",
        "User-Agent": "ClaudeCodeConnector",
    },
)
with urllib.request.urlopen(req, timeout=15) as r:
    d = json.load(r)
print(d["id"], d["channel_id"])
'
    ;;

  read)
    CHAN="${1:?usage: read <channel-id> [limit]}"
    LIMIT="${2:-10}"
    curl -sS --max-time 10 "${HEAD[@]}" \
      "$API/channels/$CHAN/messages?limit=$LIMIT" \
      | python3 -c '
import json, sys
resp = json.load(sys.stdin)
if isinstance(resp, dict):
    print("ERROR:", resp.get("message", "unknown"), "code=", resp.get("code"), file=sys.stderr)
    sys.exit(2)
for m in resp:
    author = m["author"]["username"]
    bot = " [bot]" if m["author"].get("bot") else ""
    ts = m["timestamp"]
    mid = m["id"]
    content = (m.get("content") or "").replace("\n", " \\n ")
    print(f"{ts} {mid} {author}{bot}: {content}")
'
    ;;

  wait-reply)
    CHAN="${1:?usage: wait-reply <channel-id> <since-id> [timeout]}"
    SINCE="${2:?usage: wait-reply <channel-id> <since-id> [timeout]}"
    TIMEOUT="${3:-120}"
    INTERVAL=2
    elapsed=0
    export SELF_BOT_ID
    while [ $elapsed -lt $TIMEOUT ]; do
      curl -sS --max-time 10 "${HEAD[@]}" \
        "$API/channels/$CHAN/messages?after=$SINCE&limit=50" \
        | python3 -c '
import json, os, sys
SELF = os.environ.get("SELF_BOT_ID", "")
resp = json.load(sys.stdin)
if isinstance(resp, dict):
    print("ERROR:", resp.get("message", "unknown"), "code=", resp.get("code"), file=sys.stderr)
    sys.exit(2)
for m in reversed(resp):
    if m["author"].get("id") == SELF:
        continue
    mid = m.get("id", "")
    author = m["author"].get("username", "?")
    bot = " [bot]" if m["author"].get("bot") else ""
    sys.stderr.write("MATCH " + mid + " from=" + author + bot + "\n")
    print(m.get("content") or "")
    sys.exit(0)
sys.exit(1)
' && exit 0
      sleep $INTERVAL
      elapsed=$((elapsed + INTERVAL))
    done
    echo "discord-bot: wait-reply timed out after ${TIMEOUT}s" >&2
    exit 1
    ;;

  *)
    grep -E '^# ' "$0" | sed 's/^# \?//'
    exit 1
    ;;
esac

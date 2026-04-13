#!/bin/bash
#
# setup.sh — set up the Claude Code Discord Connector
#
# Creates the token directory, installs the wrapper script, and
# verifies connectivity.
#
# Usage: bash setup.sh
#
# Prerequisites:
#   - A Discord bot created at https://discord.com/developers/applications
#   - The bot token copied
#   - The bot invited to your guild with MESSAGE CONTENT Intent enabled
#   - python3 + curl available
#   - Claude Code installed (claude CLI in PATH)

set -eu

INSTALL_DIR="${CLAUDE_CODE_CONNECTOR_DIR:-$HOME/.local/bin}"
TOKEN_DIR="$HOME/.config/claude-discord"
TOKEN_FILE="$TOKEN_DIR/token"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Claude Code Discord Connector — Setup"
echo "======================================"
echo

# Step 1: Token
mkdir -p "$TOKEN_DIR"
chmod 700 "$TOKEN_DIR"

if [ -f "$TOKEN_FILE" ] && [ -s "$TOKEN_FILE" ]; then
    echo "[1/4] Token file exists at $TOKEN_FILE"
else
    echo "[1/4] Enter your Discord bot token (paste, then Enter):"
    read -r -s BOT_TOKEN
    echo "$BOT_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo "      Token saved to $TOKEN_FILE"
fi

# Step 2: Install wrapper
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/discord-bot.sh" "$INSTALL_DIR/discord-bot.sh"
chmod +x "$INSTALL_DIR/discord-bot.sh"
echo "[2/4] Installed discord-bot.sh to $INSTALL_DIR/"

# Step 3: Verify
echo "[3/4] Verifying bot identity..."
WHOAMI=$("$INSTALL_DIR/discord-bot.sh" whoami 2>&1)
if echo "$WHOAMI" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'      Bot: {d[\"username\"]}#{d.get(\"discriminator\",\"0\")} (ID: {d[\"id\"]})')" 2>/dev/null; then
    echo "      Token is valid."
else
    echo "      WARNING: Could not verify bot identity. Check your token."
    echo "      Raw response: $WHOAMI"
fi

# Step 4: List guilds
echo "[4/4] Guilds this bot is in:"
"$INSTALL_DIR/discord-bot.sh" guilds 2>/dev/null | while read -r id name; do
    echo "      $id  $name"
done

echo
echo "Setup complete. Usage:"
echo "  discord-bot.sh whoami              — verify identity"
echo "  discord-bot.sh channels <guild-id> — list channels"
echo "  discord-bot.sh read <channel-id>   — read messages"
echo "  discord-bot.sh send <channel-id> <message> — send a message"
echo
echo "For persistent monitoring from Claude Code, use the Monitor tool:"
echo "  See SKILL.md for the polling pattern."

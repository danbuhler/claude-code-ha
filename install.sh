#!/bin/bash
# Claude Code for Home Assistant - Setup Script
# https://github.com/danbuhler/claude-code-ha
#
# This script installs dependencies and sets up the CLI tools.
#
# IMPORTANT: HA OS updates reset the root filesystem!
# Re-run this script after each Home Assistant OS update.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Claude Code for Home Assistant Setup ==="
echo ""

# Detect OS
if command -v apk &> /dev/null; then
    PKG_MANAGER="apk"
    INSTALL_CMD="apk add --quiet"
elif command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="apt-get install -y"
elif command -v brew &> /dev/null; then
    PKG_MANAGER="brew"
    INSTALL_CMD="brew install"
else
    echo "Warning: Unknown package manager. Please install dependencies manually:"
    echo "  python3, pip, curl, jq, nodejs, npm"
    PKG_MANAGER="unknown"
fi

# Install system dependencies
if [ "$PKG_MANAGER" != "unknown" ]; then
    echo "Installing system packages..."
    case "$PKG_MANAGER" in
        apk)
            $INSTALL_CMD python3 py3-pip npm nodejs curl jq
            ;;
        apt)
            sudo $INSTALL_CMD python3 python3-pip curl jq nodejs npm
            ;;
        brew)
            $INSTALL_CMD python3 curl jq node
            ;;
    esac
fi

# Install Python dependencies
echo "Installing Python websockets..."
if command -v pip3 &> /dev/null; then
    pip3 install websockets --break-system-packages --quiet 2>/dev/null || pip3 install websockets --quiet
elif command -v pip &> /dev/null; then
    pip install websockets --quiet
fi

# Install Claude Code
echo "Installing Claude Code..."
if command -v npm &> /dev/null; then
    # npm exits with EEXIST when /usr/local/bin/claude already exists, e.g. a
    # native install linked there. Under `set -e` that aborted the whole script
    # at this line, skipping the tool symlinks, the .env seeding and the PATH
    # file below. Keep going instead, but say so.
    npm install -g @anthropic-ai/claude-code --silent 2>/dev/null || npm install -g @anthropic-ai/claude-code || echo "Warning: npm install of Claude Code failed; continuing with the rest of the setup"
else
    echo "Warning: npm not found. Please install Claude Code manually:"
    echo "  npm install -g @anthropic-ai/claude-code"
fi

# Make scripts executable
chmod +x "$SCRIPT_DIR/bin/"*

# Determine HA config directory (prefer /config as it's the standard HA path)
if [ -d "/config" ]; then
    HA_CONFIG="/config"
elif [ -d "/homeassistant" ]; then
    HA_CONFIG="/homeassistant"
else
    HA_CONFIG="$HOME"
fi

# Determine bin install location
if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    BIN_DIR="/usr/local/bin"
elif [ -d "$HOME/.local/bin" ]; then
    BIN_DIR="$HOME/.local/bin"
else
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
fi

# Create symlinks for tools (these get wiped on HA OS update, safe to recreate)
echo ""
echo "Creating symlinks in $BIN_DIR..."
for script in ha-api ha-ws lovelace-sync; do
    if [ -f "$SCRIPT_DIR/bin/$script" ]; then
        ln -sf "$SCRIPT_DIR/bin/$script" "$BIN_DIR/$script"
        echo "  [symlink] $script -> $SCRIPT_DIR/bin/$script"
    fi
done

# Copy CLAUDE.md to HA config (only if it doesn't exist - won't overwrite customizations)
echo ""
echo "Copying CLAUDE.md to $HA_CONFIG..."
if [ -f "$HA_CONFIG/CLAUDE.md" ]; then
    echo "  [skipped] CLAUDE.md already exists (won't overwrite your customizations)"
    echo "            To update, manually copy from: $SCRIPT_DIR/CLAUDE.md"
else
    cp "$SCRIPT_DIR/CLAUDE.md" "$HA_CONFIG/CLAUDE.md"
    echo "  [copied] CLAUDE.md -> $HA_CONFIG/CLAUDE.md"
fi

# Copy .env.example if .env doesn't exist
if [ ! -f "$HA_CONFIG/.env" ]; then
    if [ -f "$SCRIPT_DIR/.env.example" ]; then
        cp "$SCRIPT_DIR/.env.example" "$HA_CONFIG/.env"
        echo "  [copied] .env.example -> $HA_CONFIG/.env (edit this with your token!)"
    fi
else
    echo "  [skipped] .env already exists"
fi

# Add to PATH if needed (for HA OS)
if [ -d "/etc/profile.d" ] && [ -w "/etc/profile.d" ]; then
    PROFILE_FILE="/etc/profile.d/claude-ha.sh"
    echo ""
    echo "Adding tools to PATH..."
    cat > "$PROFILE_FILE" << EOF
# Claude Code for Home Assistant
export PATH="\$PATH:$BIN_DIR:$SCRIPT_DIR/bin"
EOF
    chmod +x "$PROFILE_FILE"
fi

# Disable HA banner (HA OS specific)
if [ -f "/etc/profile.d/homeassistant.sh" ]; then
    echo "Disabling HA banner..."
    sed -i 's/^ha banner/# ha banner/' /etc/profile.d/homeassistant.sh 2>/dev/null || true
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "What was installed:"
echo "  [symlinks - recreated each run]"
echo "    ha-api, ha-ws, lovelace-sync -> $BIN_DIR/"
echo ""
echo "  [copies - only if not present, won't overwrite]"
echo "    CLAUDE.md -> $HA_CONFIG/"
echo "    .env      -> $HA_CONFIG/"
echo ""
echo "Next steps:"
if [ -f "$HA_CONFIG/.env" ]; then
    if grep -q "your_long_lived_access_token_here" "$HA_CONFIG/.env" 2>/dev/null; then
        echo "  1. Edit $HA_CONFIG/.env and add your HA token"
        echo "  2. Run 'claude' to start Claude Code"
    else
        echo "  1. Run 'claude' to start Claude Code"
    fi
else
    echo "  1. Create $HA_CONFIG/.env with HA_URL and HA_TOKEN"
    echo "  2. Run 'claude' to start Claude Code"
fi
echo ""
echo "Run 'source /etc/profile.d/claude-ha.sh' or start a new shell to use the tools."

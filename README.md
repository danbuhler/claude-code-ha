# Claude Code for Home Assistant

CLI tools and configuration for using [Claude Code](https://claude.com/claude-code) with Home Assistant OS.

## What's Included

| File | Description |
|------|-------------|
| `bin/ha-api` | REST API CLI for quick state/service operations |
| `bin/ha-ws` | WebSocket CLI for registry management and detailed lookups |
| `bin/lovelace-sync` | Push dashboard changes to HA without restart |
| `install.sh` | Setup script for HA OS (re-run after updates) |
| `CLAUDE.md` | Instructions file that Claude Code reads automatically |

## Prerequisites

### Terminal & SSH Add-on Setup

Install the "Terminal & SSH" add-on from the Home Assistant Add-on Store, then configure it with the required packages:

1. Go to **Settings → Add-ons → Terminal & SSH → Configuration**
2. Add these packages to the configuration:

```yaml
apks:
  - gcompat
  - libstdc++
  - curl
  - procps
  - coreutils
  - tar
  - bash
  - python3
  - py3-pip
  - fzf
```

3. Save and restart the add-on

## Installation

### Getting a Long-Lived Access Token

1. Go to your Home Assistant profile (click your name in sidebar)
2. Switch to the **Security** tab
3. Scroll to "Long-Lived Access Tokens"
4. Click "Create Token"
5. Save the token for the next step

### On Home Assistant OS

```bash
# SSH into your HA OS instance
cd /config

# Clone this repo
git clone https://github.com/danbuhler/claude-code-ha.git

# Run setup (installs dependencies + Claude Code)
cd claude-code-ha
./install.sh

# Edit /config/.env and add your long-lived access token
nano /config/.env
```

### Manual Installation (what install.sh does for you)

```bash
# Install dependencies
apk add python3 py3-pip curl jq nodejs npm
pip3 install websockets --break-system-packages

# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Copy scripts to PATH
cp bin/* /usr/local/bin/
chmod +x /usr/local/bin/ha-*
chmod +x /usr/local/bin/lovelace-sync

# Copy CLAUDE.md and .env to your HA config directory
cp CLAUDE.md /config/
cp .env.example /config/.env
nano /config/.env  # Add your token
```

## Usage

### ha-api - REST API CLI

Fast lookups and service calls:

```bash
ha-api states                    # List all entities
ha-api states light              # Filter by domain
ha-api state light.kitchen       # Get specific entity state
ha-api attr sensor.temperature   # Show attributes
ha-api devices motion            # Find by device_class
ha-api search bedroom            # Search entity IDs
ha-api call light turn_on        # Call a service
ha-api history sensor.temp 48    # Get 48h history
```

### ha-ws - WebSocket CLI

Registry management and detailed entity/device info:

```bash
# Entity operations
ha-ws entity list light          # List light entities
ha-ws entity get light.kitchen   # Full entity details + related items
ha-ws entity update light.old new_entity_id=light.new  # Rename

# Device operations
ha-ws device list                # List all devices
ha-ws device get <device_id>     # Device details + all entities

# Area management
ha-ws area list                  # List areas
ha-ws area create "Guest Room"   # Create area

# Service calls
ha-ws call light.turn_on entity_id=light.kitchen brightness=255

# Raw WebSocket
ha-ws raw config/entity_registry/list
ha-ws raw config/entity_registry/get entity_id=light.kitchen   # key=value params
ha-ws raw config_entries/ignore_flow '{"flow_id":"X","title":"Y"}'   # or a JSON object
```

### lovelace-sync - Dashboard Sync

Edit `.storage/lovelace` directly, then push to HA:

```bash
# 1. Edit the lovelace file
# 2. Push changes (no restart needed)
lovelace-sync
# 3. Refresh browser to see changes
```

**Note:** Changes made in the HA web interface will overwrite any unpushed local edits. Always run `lovelace-sync` before making changes in the UI.

## Claude Code Integration

The `CLAUDE.md` file provides Claude Code with context about:
- These CLI tools and how to use them
- Home Assistant YAML configuration patterns
- Best practices for automation/template syntax

Copy `CLAUDE.md` to your HA config directory. Claude Code automatically reads it when working there.

### Example Session

```
> claude

You: "Turn on the kitchen lights"
Claude: *uses ha-api call light turn_on*

You: "What motion sensors do I have?"
Claude: *uses ha-api devices motion*

You: "Rename light.old_lamp to light.bedroom_lamp"
Claude: *uses ha-ws entity update*
```

## Configuration

### Environment Variables

The install script creates `/config/.env` from the template. Edit it with your token:

```bash
# /config/.env
HA_URL=https://172.30.32.1:8128   # Internal HA API URL (HA OS default)
HA_TOKEN=your_token_here          # Long-lived access token
```

The scripts search for `.env` in order:
1. `$HA_ENV_FILE` (if set)
2. `/config/.env` (standard location)
3. `/homeassistant/.env`
4. Current directory
5. `~/.ha-cli.env`

### For External Access

If running Claude Code from outside HA OS:

```bash
HA_URL=https://your-ha-domain.com:8123
HA_TOKEN=your_token_here
```

## After Home Assistant OS Updates

HA OS updates reset the root filesystem, removing installed packages and PATH modifications. **Re-run `install.sh` after each HA OS update:**

```bash
cd /config/claude-code-ha  # or wherever you cloned it
./install.sh
```

### What install.sh Does

| Item | Action | On Re-run |
|------|--------|-----------|
| System packages (python3, nodejs, etc.) | Installs via apk | Reinstalls (needed after HA update) |
| Python websockets | pip install | Reinstalls (needed after HA update) |
| Claude Code | npm install -g | Reinstalls (needed after HA update) |
| `ha-api`, `ha-ws`, `lovelace-sync` | **Symlinks** to repo's `bin/` | Recreates (safe) |
| `CLAUDE.md` | **Copies** to `/config/` | Skips if exists (preserves customizations) |
| `.env` | **Copies** template to `/config/.env` | Skips if exists (preserves your token) |
| PATH in `/etc/profile.d/` | Creates | Recreates (needed after HA update) |

**Symlinks** point to the scripts in the repo - updates to the repo are immediately available.

**Copies** are only made on first run. If you've customized `CLAUDE.md`, it won't be overwritten. To get updates, manually copy from the repo.

### What Persists Across HA Updates

These survive in `/config`:
- The cloned repo itself
- Your `.env` file (with your token)
- Your customized `CLAUDE.md`

## Requirements

- Home Assistant (any installation with shell access)
- Python 3 with `websockets` package
- `curl` and `jq` for ha-api
- Node.js/npm for Claude Code

## License

MIT License - See [LICENSE](LICENSE)
